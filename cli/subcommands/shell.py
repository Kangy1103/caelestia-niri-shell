import subprocess
import os
from argparse import Namespace

from cns.utils.paths import c_cache_dir


class Command:
    args: Namespace

    def __init__(self, args: Namespace) -> None:
        self.args = args

    def run(self) -> None:
        if self.args.show:
            self.print_ipc()
        elif self.args.log:
            self.print_log()
        elif self.args.kill or (self.args.message and self.args.message == ["kill"]):
            self._kill()
        elif self.args.message:
            if self.args.message == ["start"]:
                self._start()
            else:
                self.message(*self.args.message)
        else:
            self._start()

    def _kill(self) -> None:
        subprocess.run(["/usr/bin/pkill", "-f", "qs -c"], check=False)

    def _start(self) -> None:
        os.remove("/tmp/quickshell_screenshot.sock") if os.path.exists("/tmp/quickshell_screenshot.sock") else None
        args = ["qs", "-c", "caelestia-niri-shell"]
        if self.args.log_rules:
            args.extend(["--log-rules", self.args.log_rules])
        if self.args.daemon:
            args.append("-d")
            subprocess.run(args)
        else:
            args.append("-n")
            shell = subprocess.Popen(args, stdout=subprocess.PIPE, universal_newlines=True)
            if shell.stdout:
                for line in shell.stdout:
                    if self.filter_log(line):
                        print(line, end="")

    def shell(self, *args: str) -> str:
        return subprocess.check_output(["qs", "-c", "caelestia-niri-shell", *args], text=True)

    def filter_log(self, line: str) -> bool:
        return f"Cannot open: file://{c_cache_dir}/imagecache/" not in line

    def print_ipc(self) -> None:
        print(self.shell("ipc", "show"), end="")

    def print_log(self) -> None:
        if self.args.log_rules:
            log = self.shell("log", "-r", self.args.log_rules)
        else:
            log = self.shell("log")
        # FIXME: remove when logging rules are added/warning is removed
        for line in log.splitlines():
            if self.filter_log(line):
                print(line)

    def message(self, *args: list[str]) -> None:
        print(self.shell("ipc", "call", *args), end="")
