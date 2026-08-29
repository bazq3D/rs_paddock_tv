document.addEventListener('DOMContentLoaded', function() {
    var isPlaying = true;
    var toggleBtn = document.getElementById('btn-toggle-play');

    if (toggleBtn) {
        toggleBtn.addEventListener('click', function() {
            isPlaying = !isPlaying;
            if (isPlaying) {
                toggleBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
            } else {
                toggleBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
            }
        });
    }

    // Listen for live radio track data pushed from FiveM DUI
    window.addEventListener('message', function(event) {
        var data = event.data;
        if (!data) return;

        if (data.type === 'rsradio:data' || data.trackTitle) {
            var titleEl = document.getElementById('song-title');
            if (titleEl && data.trackTitle) {
                titleEl.innerText = data.trackTitle;
            }
        }
    });
});
