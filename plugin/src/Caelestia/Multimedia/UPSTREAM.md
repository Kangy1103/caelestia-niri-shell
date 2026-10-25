# Upstream provenance

Ported from caelestia-dots/shell at 4b1dae84b1b3b28bf486776ba30c1c1ec74fb64d (25 October 2026). The VisualSource, Visual, worker-thread cache, size buckets, LRU index and optional BC3 encoder follow upstream.

CNS adaptations:

- CNS QML URI/target and cache namespace; existing CNS.Images remains available to older consumers.
- Lossless PNG caches by default to preserve wallpaper gradients. The upstream BC3 path is opt-in with CNS_IMAGE_CACHE_BC3=1 for comparisons.
- Explicit callback shutdown before VisualSource member destruction and guarded QML item/output pointers.
- Millisecond modification times in cache keys.
- Two encoder worker threads instead of consuming the global Qt pool.
- CNS wallpaper transitions retain existing duration/easing, fit modes and picker preview coordination.
- Clear stale readiness on source changes, expose media failures, and propagate missing image paths to QML's error handling.
- Transition snapshots are released after use; normal still wallpapers do not retain a transition render target.

The vendored rgbcx license is in plugin/3rdparty/rgbcx/LICENSE.
