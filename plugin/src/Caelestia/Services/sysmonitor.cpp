#include "sysmonitor.hpp"

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QProcess>
#include <QRegularExpression>
#include <QDebug>
#include <sys/sysinfo.h>
#include <unistd.h>

namespace caelestia {

SysMonitor::SysMonitor(QObject* parent) : QObject(parent) {
    m_clockTicks = sysconf(_SC_CLK_TCK);

    QFile meminfo("/proc/meminfo");
    if (meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&meminfo);
        while (!in.atEnd()) {
            const QString line = in.readLine().trimmed();
            if (line.startsWith("MemTotal:")) {
                m_memTotalKB = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts).value(1).toLongLong();
                break;
            }
        }
    }
    if (m_memTotalKB <= 0) m_memTotalKB = 1;

    connect(&m_timer, &QTimer::timeout, this, &SysMonitor::updateAll);
    m_timer.setInterval(m_updateInterval);
    updateSystemOnce();
}

SysMonitor::~SysMonitor() {}

QVariantList SysMonitor::disk() const { return m_disk; }
QVariantList SysMonitor::processes() const { return m_processes; }
QVariantMap SysMonitor::system() const { return m_system; }

int SysMonitor::updateInterval() const { return m_updateInterval; }
void SysMonitor::setUpdateInterval(int interval) {
    if (m_updateInterval != interval) {
        m_updateInterval = interval;
        m_timer.setInterval(m_updateInterval);
        emit updateIntervalChanged();
    }
}

int SysMonitor::maxProcesses() const { return m_maxProcesses; }
void SysMonitor::setMaxProcesses(int max) {
    if (m_maxProcesses != max) {
        m_maxProcesses = max;
        emit maxProcessesChanged();
    }
}

QString SysMonitor::sortBy() const { return m_sortBy; }
void SysMonitor::setSortBy(const QString& sort) {
    if (m_sortBy != sort) {
        m_sortBy = sort;
        emit sortByChanged();
    }
}

void SysMonitor::start() {
    if (!m_timer.isActive()) {
        updateAll();
        m_timer.start();
    }
}

void SysMonitor::stop() {
    m_timer.stop();
}

void SysMonitor::updateAll() {
    updateDisk();
    updateProcesses();
}

void SysMonitor::updateDisk() {
    QFile file("/proc/diskstats");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QTextStream in(&file);
    QVariantList newDisk;
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        QStringList parts = line.split(" ", Qt::SkipEmptyParts);
        if (parts.size() < 14) continue;
        QString name = parts[2];
        if (!name.startsWith("sd") && !name.startsWith("nvme") && !name.startsWith("vd")) continue;
        // Skip partitions (crude checking: if name ends in digit for sd or p\d+ for nvme)
        if (name.startsWith("sd") && name.at(name.length()-1).isDigit()) continue;
        if (name.startsWith("nvme") && name.contains("p")) continue;

        QVariantMap d;
        d["name"] = name;
        d["read"] = parts[5].toLongLong(); // sectors read
        d["write"] = parts[9].toLongLong(); // sectors written
        newDisk.append(d);
    }
    
    m_disk = newDisk;
    emit diskChanged();
}

void SysMonitor::updateSystem() {
    QFile file("/proc/loadavg");
    if (file.open(QIODevice::ReadOnly)) m_system["loadavg"] = QString::fromUtf8(file.readAll().trimmed().split(' ').mid(0,3).join(' '));
    file.close();

    struct sysinfo si;
    if (sysinfo(&si) == 0) {
        m_sysUptime = si.uptime;
        m_system["processes"] = si.procs;
    }
}

void SysMonitor::updateSystemOnce() {
    updateSystem(); // Grab first uptime
    
    // Set static system values
    QFile rel("/etc/os-release");
    if (rel.open(QIODevice::ReadOnly)) {
        QTextStream in(&rel);
        while(!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("PRETTY_NAME=")) {
                m_system["distro"] = line.section("=", 1).replace("\"", "");
                break;
            }
        }
    }
    
    QProcess uname;
    uname.start("uname", QStringList() << "-r" << "-m");
    uname.waitForFinished();
    QStringList outs = QString::fromUtf8(uname.readAllStandardOutput()).trimmed().split(" ", Qt::SkipEmptyParts);
    if(outs.size()>=2) {
        m_system["kernel"] = outs[0];
        m_system["arch"] = outs[1];
    }
    
    char hostname[256];
    if (gethostname(hostname, sizeof(hostname)) == 0) m_system["hostname"] = QString::fromUtf8(hostname);
    
    QFile dm("/sys/class/dmi/id/board_vendor");
    if (dm.open(QIODevice::ReadOnly)) m_system["motherboard"] = QString::fromUtf8(dm.readAll().trimmed());
    
    emit systemChanged();
}

void SysMonitor::updateProcesses() {
    updateSystem(); // Needed for uptime calculation
    
    QDir procDir("/proc");
    QStringList pidDirs = procDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    
    QHash<int, ProcessInfo> newProcesses;
    QVariantList parsedProcs;

    for (const QString& pidStr : pidDirs) {
        bool ok;
        int pid = pidStr.toInt(&ok);
        if (!ok) continue;

        QFile statFile(QString("/proc/%1/stat").arg(pid));
        if (!statFile.open(QIODevice::ReadOnly | QIODevice::Text)) continue;
        
        QString statContent = statFile.readAll();
        // Comm name is enclosed in parenthesis
        int leftParen = statContent.indexOf("(");
        int rightParen = statContent.lastIndexOf(")");
        if(leftParen == -1 || rightParen == -1) continue;

        QString comm = statContent.mid(leftParen + 1, rightParen - leftParen - 1);
        QString afterCommm = statContent.mid(rightParen + 2);
        QStringList parts = afterCommm.split(" ", Qt::SkipEmptyParts);
        
        if (parts.size() < 22) continue; // safety
        
        int ppid = parts[1].toInt();
        qint64 utime = parts[11].toLongLong();
        qint64 stime = parts[12].toLongLong();
        qint64 starttime = parts[19].toLongLong();
        qint64 rss = parts[21].toLongLong(); // blocks 

        // Rss is allocated in pages, multiply by page size
        qint64 memoryKbs = (rss * sysconf(_SC_PAGESIZE)) / 1024;
        
        ProcessInfo pi;
        pi.pid = pid;
        pi.ppid = ppid;
        pi.memoryKB = memoryKbs;
        pi.memoryPercent = (double)pi.memoryKB / (double)m_memTotalKB * 100.0;
        pi.command = comm;
        pi.utime = utime;
        pi.stime = stime;

        // CPU calculation
        pi.cpu = 0.0;
        if (m_lastProcesses.contains(pid)) {
             ProcessInfo lastPi = m_lastProcesses[pid];
             qint64 total_time = (pi.utime + pi.stime) - (lastPi.utime + lastPi.stime);
             double seconds = ((double)m_updateInterval / 1000.0); // Exact elapsed interval roughly
             if (seconds > 0) {
                 pi.cpu = 100.0 * ((double)total_time / (double)m_clockTicks) / seconds;
             }
        }
        
        // Command line arguments for full detail caching
        QFile cmdFile(QString("/proc/%1/cmdline").arg(pid));
        if (cmdFile.open(QIODevice::ReadOnly)) {
            QByteArray cmdData = cmdFile.readAll();
            cmdData.replace('\0', ' ');
            pi.fullCommand = QString::fromUtf8(cmdData.trimmed());
        }
        if (pi.fullCommand.isEmpty()) pi.fullCommand = pi.command;

        newProcesses[pid] = pi;
    }
    
    m_lastProcesses = newProcesses;

    // Sort to QVariantList depending on m_sortBy
    QList<ProcessInfo> list = newProcesses.values();
    std::sort(list.begin(), list.end(), [&](const ProcessInfo& a, const ProcessInfo& b) {
        if (m_sortBy == "cpu") return a.cpu > b.cpu;
        if (m_sortBy == "memory") return a.memoryPercent > b.memoryPercent;
        if (m_sortBy == "pid") return a.pid > b.pid;
        return a.command < b.command; // default name a-z
    });
    
    int limit = qMin(m_maxProcesses, list.size());
    for(int i = 0; i < limit; i++) {
        QVariantMap p;
        p["pid"] = list[i].pid;
        p["ppid"] = list[i].ppid;
        p["cpu"] = list[i].cpu;
        p["memoryPercent"] = list[i].memoryPercent;
        p["memoryKB"] = list[i].memoryKB;
        p["command"] = list[i].command;
        p["fullCommand"] = list[i].fullCommand;
        
        QString displayName = list[i].command;
        if (displayName.length() > 15) displayName = displayName.left(15) + "...";
        p["displayName"] = displayName;
        
        parsedProcs.append(p);
    }

    if (m_processes != parsedProcs) {
        m_processes = parsedProcs;
        emit processesChanged();
    }
}

} // namespace caelestia
