document.addEventListener('DOMContentLoaded', function() {
    var widget = document.getElementById('radio-widget');
    var positions = ['pos-top-left', 'pos-top-right', 'pos-bottom-right', 'pos-bottom-left'];
    var currentPosIndex = 0;

    // Smoothly shift widget position across the 4 corners of the screen every 18 seconds
    setInterval(function() {
        if (!widget) return;
        positions.forEach(function(p) { widget.classList.remove(p); });
        currentPosIndex = (currentPosIndex + 1) % positions.length;
        widget.classList.add(positions[currentPosIndex]);
    }, 18000);

    // Play/Pause button toggle
    var toggleBtn = document.getElementById('btn-toggle-play');
    var isPlaying = true;
    if (toggleBtn) {
        toggleBtn.addEventListener('click', function() {
            isPlaying = !isPlaying;
            if (isPlaying) {
                toggleBtn.innerHTML = '<i class="fa-solid fa-square"></i>';
            } else {
                toggleBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
            }
        });
    }

    // Listen for live track & station data pushed from FiveM DUI
    window.addEventListener('message', function(event) {
        var data = event.data;
        if (!data) return;

        if (data.type === 'rsradio:data' || data.trackTitle) {
            var titleEl = document.getElementById('song-title');
            if (titleEl && data.trackTitle) {
                titleEl.innerText = data.trackTitle;
            }
            var stationEl = document.getElementById('station-name');
            if (stationEl && data.stationName) {
                stationEl.innerText = data.stationName;
            }
        }
    });
});
