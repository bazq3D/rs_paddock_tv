document.addEventListener('DOMContentLoaded', function() {
    var widget = document.getElementById('radio-widget');
    var positions = ['pos-top-left', 'pos-top-right', 'pos-bottom-right', 'pos-bottom-left'];
    var currentPosIndex = 0;

    // Smooth 4-corner position drift every 18 seconds
    setInterval(function() {
        if (!widget) return;
        positions.forEach(function(p) { widget.classList.remove(p); });
        currentPosIndex = (currentPosIndex + 1) % positions.length;
        widget.classList.add(positions[currentPosIndex]);
    }, 18000);

    // Default Scenery Images
    var sceneryList = [
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1280", // Beach Sunset
        "https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=1280", // Mountain Night Sky
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1280", // Yosemite Valley
        "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1280"  // Foggy Mountain Forest
    ];
    var sceneryInterval = 12000;
    var currentSceneryIndex = 0;

    var slideA = document.getElementById('slide-a');
    var slideB = document.getElementById('slide-b');
    var activeSlide = 'a';

    function loadInitialScenery() {
        if (sceneryList.length > 0 && slideA) {
            slideA.style.backgroundImage = 'url("' + sceneryList[0] + '")';
            slideA.classList.add('active');
        }
    }
    loadInitialScenery();

    // Crossfade scenery slideshow
    setInterval(function() {
        if (sceneryList.length <= 1) return;
        currentSceneryIndex = (currentSceneryIndex + 1) % sceneryList.length;
        var nextImgUrl = sceneryList[currentSceneryIndex];

        if (activeSlide === 'a') {
            if (slideB) {
                slideB.style.backgroundImage = 'url("' + nextImgUrl + '")';
                slideB.classList.add('active');
            }
            if (slideA) slideA.classList.remove('active');
            activeSlide = 'b';
        } else {
            if (slideA) {
                slideA.style.backgroundImage = 'url("' + nextImgUrl + '")';
                slideA.classList.add('active');
            }
            if (slideB) slideB.classList.remove('active');
            activeSlide = 'a';
        }
    }, sceneryInterval);

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

    // Listen for live track & custom scenery data pushed from FiveM DUI
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
        if (data.sceneryImages && Array.isArray(data.sceneryImages) && data.sceneryImages.length > 0) {
            sceneryList = data.sceneryImages;
        }
    });
});
