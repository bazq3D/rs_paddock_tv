var currentScope = 'single'; // 'single', 'group', 'all'
var currentTvId = 1;
var currentGroupId = 1;
var currentLocationKey = null;
var tvListMap = {};
var tvGroupsMap = {};
var tvStatesMap = {};
var localesMap = {};

// Locale Helper Function
function _L(key, defaultText) {
    if (localesMap && localesMap[key]) {
        return localesMap[key];
    }
    return defaultText !== undefined ? defaultText : key;
}

// Tüm DOM Elemanlarına Dil Çevirilerini Uygular
function applyLocalesToUI() {
    // Header
    var headerTitle = document.querySelector('.title-wrapper h1');
    if (headerTitle) headerTitle.innerText = _L('ui_header_title', 'MASTER PADDOCK TV CONTROL');

    var headerSub = document.querySelector('.title-wrapper .subtitle');
    if (headerSub) headerSub.innerText = _L('ui_header_subtitle', 'BROADCAST CONTROL ROOM // 7-SCREEN MATRIX STATION');

    // Scope Buttons
    var scopeAll = document.getElementById('scope-btn-all');
    if (scopeAll) scopeAll.innerHTML = `<i class="fa-solid fa-globe"></i> ${_L('ui_scope_all', 'SYNC ALL 7 TVs')}`;

    var scopeG1 = document.getElementById('scope-btn-g1');
    if (scopeG1) scopeG1.innerHTML = `<i class="fa-solid fa-layer-group"></i> ${_L('ui_scope_g1', 'LEFT BAR (TV 1-4)')}`;

    var scopeG2 = document.getElementById('scope-btn-g2');
    if (scopeG2) scopeG2.innerHTML = `<i class="fa-solid fa-layer-group"></i> ${_L('ui_scope_g2', 'RIGHT BAR (TV 5-7)')}`;

    // Bar Section Badges
    var sectionBadges = document.querySelectorAll('.section-badge');
    if (sectionBadges && sectionBadges.length >= 2) {
        sectionBadges[0].innerHTML = `<i class="fa-solid fa-desktop"></i> ${_L('ui_left_bar_badge', 'LEFT BAR (TV 1-4)')}`;
        sectionBadges[1].innerHTML = `<i class="fa-solid fa-desktop"></i> ${_L('ui_right_bar_badge', 'RIGHT BAR (TV 5-7)')}`;
    }

    // Input & Actions
    var customUrlLabel = document.querySelector('.custom-url-card label');
    if (customUrlLabel) customUrlLabel.innerHTML = `<i class="fa-brands fa-youtube"></i> ${_L('ui_custom_url', 'YOUTUBE STREAM URL / LINK')}`;

    var playCustomBtn = document.getElementById('play-custom-btn');
    if (playCustomBtn) playCustomBtn.innerHTML = `<i class="fa-solid fa-play"></i> ${_L('ui_play', 'PLAY')}`;

    var actionPause = document.getElementById('action-pause');
    if (actionPause) actionPause.innerHTML = `<i class="fa-solid fa-pause"></i> ${_L('ui_pause', 'PAUSE')}`;

    var actionResume = document.getElementById('action-resume');
    if (actionResume) actionResume.innerHTML = `<i class="fa-solid fa-play"></i> ${_L('ui_resume', 'RESUME')}`;

    var actionStop = document.getElementById('action-stop');
    if (actionStop) actionStop.innerHTML = `<i class="fa-solid fa-power-off"></i> ${_L('ui_stop', 'STOP TV')}`;

    // Side Cards
    var scopeTitle = document.querySelector('.scope-card h4');
    if (scopeTitle) scopeTitle.innerHTML = `<i class="fa-solid fa-bullseye"></i> ${_L('ui_scope_title', 'BROADCAST TARGET SCOPE')}`;

    var detailsTitle = document.querySelector('.details-card h4');
    if (detailsTitle) detailsTitle.innerHTML = `<i class="fa-solid fa-location-dot"></i> ${_L('ui_interior_details', 'INTERIOR DETAILS')}`;

    var detailRowLabels = document.querySelectorAll('.detail-row .label');
    if (detailRowLabels && detailRowLabels.length >= 2) {
        detailRowLabels[0].innerText = _L('ui_location', 'LOCATION');
        detailRowLabels[1].innerText = _L('ui_coordinates', 'COORDINATES');
    }

    var volumeTitle = document.querySelector('.volume-card h4');
    if (volumeTitle) volumeTitle.innerHTML = `<i class="fa-solid fa-volume-high"></i> ${_L('ui_volume_control', 'VOLUME CONTROL')}`;
}

// Esc ve Kapat Butonu Dinleyicileri
document.getElementById('close-btn').addEventListener('click', closeUI);
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' || event.key === 'Esc') {
        closeUI();
    }
});

function closeUI() {
    document.getElementById('ui-wrapper').style.display = 'none';
    if (typeof GetParentResourceName !== 'undefined') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({})
        });
    }
}

// Scope Hızlı Eylem Butonları
document.getElementById('scope-btn-all').addEventListener('click', function() {
    setScope('all');
});
document.getElementById('scope-btn-g1').addEventListener('click', function() {
    setScope('group', 1);
});
document.getElementById('scope-btn-g2').addEventListener('click', function() {
    setScope('group', 2);
});

function setScope(scope, groupId) {
    currentScope = scope;
    if (groupId) currentGroupId = groupId;
    updateScopeButtonsUI();
    updateUIStateForCurrentScope();
}

function updateScopeButtonsUI() {
    document.getElementById('scope-btn-all').className = 'scope-btn' + (currentScope === 'all' ? ' active' : '');
    document.getElementById('scope-btn-g1').className = 'scope-btn' + (currentScope === 'group' && currentGroupId === 1 ? ' active' : '');
    document.getElementById('scope-btn-g2').className = 'scope-btn' + (currentScope === 'group' && currentGroupId === 2 ? ' active' : '');
}

// YouTube Video ID Çıkarma Helper
function getYoutubeId(url) {
    if (!url) return "";
    var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regExp);
    return (match && match[2].length === 11) ? match[2] : url;
}

// FiveM NUI Olay Dinleyicisi
window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.action === 'show') {
        document.getElementById('ui-wrapper').style.display = 'flex';
        
        currentScope = 'single';
        currentTvId = parseInt(data.selectedTvId) || 1;
        currentLocationKey = data.locationKey || null;
        tvListMap = data.tvList || {};
        tvGroupsMap = data.tvGroups || {};
        tvStatesMap = data.tvStates || {};
        localesMap = data.locales || {};

        applyLocalesToUI();

        if (data.locationLabel) {
            document.getElementById('active-interior').innerText = data.locationLabel;
        }
        if (data.locationCoords) {
            document.getElementById('active-coords').innerText = data.locationCoords;
        }

        renderTvMatrix();
        updateScopeButtonsUI();
        updateUIStateForCurrentScope();

    } else if (data.action === 'syncState') {
        if (data.tvStates) {
            tvStatesMap = data.tvStates;
        } else if (data.tvId && data.state) {
            tvStatesMap[data.tvId] = data.state;
        }
        renderTvMatrix();
        if (document.getElementById('ui-wrapper').style.display === 'flex') {
            updateUIStateForCurrentScope();
        }
    } else if (data.action === 'syncAllStates') {
        if (data.tvStates) {
            tvStatesMap = data.tvStates;
            renderTvMatrix();
            if (document.getElementById('ui-wrapper').style.display === 'flex') {
                updateUIStateForCurrentScope();
            }
        }
    }
});

// Standalone Web Tarayıcı Önizleme Modu
document.addEventListener('DOMContentLoaded', function() {
    if (typeof GetParentResourceName === 'undefined') {
        console.log("[bazq-paddock-tv] Master Control Desk Web Inspection Mode Active.");
        document.getElementById('ui-wrapper').style.display = 'flex';
        
        var mockTvList = {
            1: { name: "TV #1 (Ön Grup)", model: "rs_paddock_tv_app1" },
            2: { name: "TV #2 (Ön Grup)", model: "rs_paddock_tv_app2" },
            3: { name: "TV #3 (Ön Grup)", model: "rs_paddock_tv_app3" },
            4: { name: "TV #4 (Ön Grup)", model: "rs_paddock_tv_app4" },
            5: { name: "TV #5 (Arka Grup)", model: "rs_paddock_tv_app5" },
            6: { name: "TV #6 (Arka Grup)", model: "rs_paddock_tv_app6" },
            7: { name: "TV #7 (Arka Grup)", model: "rs_paddock_tv_app7" }
        };

        var mockTvGroups = {
            1: { id: 1, name: "SOL BAR (TV 1-4)", tvIds: [1, 2, 3, 4] },
            2: { id: 2, name: "SAĞ BAR (TV 5-7)", tvIds: [5, 6, 7] }
        };

        var mockStates = {
            1: { url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", playing: true, time: 120, volume: 30 },
            2: { url: "", playing: false, time: 0, volume: 30 },
            3: { url: "", playing: false, time: 0, volume: 30 },
            4: { url: "", playing: false, time: 0, volume: 30 },
            5: { url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", playing: true, time: 60, volume: 30 },
            6: { url: "", playing: false, time: 0, volume: 30 },
            7: { url: "", playing: false, time: 0, volume: 30 }
        };

        window.postMessage({
            action: 'show',
            tvList: mockTvList,
            tvGroups: mockTvGroups,
            selectedTvId: 1,
            tvStates: mockStates,
            locationLabel: "RS Paddock // Del Pierro",
            locationCoords: "-2202.10, -392.15, 15.08"
        }, "*");
    }
});

// Fiziksel Paddock Bar 7 TV Matrix Layout Render (Sol Bar: TV 1..4 - Sağ Bar: TV 5..7)
function renderTvMatrix() {
    var leftContainer = document.getElementById('cards-row-left');
    var rightContainer = document.getElementById('cards-row-right');
    if (!leftContainer || !rightContainer) return;

    leftContainer.innerHTML = '';
    rightContainer.innerHTML = '';

    for (var i = 1; i <= 4; i++) {
        leftContainer.appendChild(createTvCard(i));
    }
    for (var j = 5; j <= 7; j++) {
        rightContainer.appendChild(createTvCard(j));
    }
}

function createTvCard(tvId) {
    var state = tvStatesMap[tvId] || { url: "", playing: false, time: 0, volume: 30 };
    
    var card = document.createElement('div');
    
    var isActive = false;
    if (currentScope === 'all') {
        isActive = true;
    } else if (currentScope === 'group') {
        isActive = (currentGroupId === 1 && tvId >= 1 && tvId <= 4) || (currentGroupId === 2 && tvId >= 5 && tvId <= 7);
    } else {
        isActive = (currentTvId === tvId);
    }

    card.className = 'tv-card' + (isActive ? ' active' : '');

    var isLive = state.playing && state.url && state.url !== "";
    var isPaused = !state.playing && state.url && state.url !== "";

    var badgeClass = isLive ? 'badge-live' : (isPaused ? 'badge-paused' : 'badge-off');
    var dotClass = isLive ? 'dot-live' : (isPaused ? 'dot-paused' : 'dot-off');
    var statusText = isLive ? 'LIVE' : (isPaused ? 'PAUSE' : 'OFF');

    var videoId = getYoutubeId(state.url);
    var previewHtml = "";
    if (videoId && (isLive || isPaused)) {
        previewHtml = `<img src="https://img.youtube.com/vi/${videoId}/mqdefault.jpg" class="tv-card-thumb" alt="TV ${tvId} Feed">`;
    } else {
        previewHtml = `<div class="tv-card-no-feed"><i class="fa-solid fa-video-slash"></i> NO FEED</div>`;
    }

    var volVal = state.volume !== undefined ? state.volume : 30;

    card.innerHTML = `
        <div class="tv-card-header">
            <span class="tv-card-title"><i class="fa-solid fa-tv"></i> TV #${tvId}</span>
            <span class="tv-status-badge ${badgeClass}">
                <span class="status-dot ${dotClass}"></span> ${statusText}
            </span>
        </div>
        <div class="tv-card-preview-frame">
            ${previewHtml}
        </div>
        <div class="tv-card-vol-controls">
            <i class="fa-solid fa-volume-low"></i>
            <input type="range" class="card-vol-slider" data-tvid="${tvId}" min="0" max="100" value="${volVal}">
            <span class="card-vol-text">${volVal}%</span>
        </div>
    `;

    // Tıklama ile bu TV'yi odakla (Ses slider'ı tıklamaları haricinde)
    card.addEventListener('click', function(e) {
        if (e.target.classList.contains('card-vol-slider')) return;
        currentScope = 'single';
        currentTvId = tvId;
        updateScopeButtonsUI();
        renderTvMatrix();
        updateUIStateForCurrentScope();
    });

    // Kart içi bağımsız TV Ses Slider Dinleyicisi
    var slider = card.querySelector('.card-vol-slider');
    var textVal = card.querySelector('.card-vol-text');
    if (slider) {
        slider.addEventListener('click', function(e) { e.stopPropagation(); });
        slider.addEventListener('input', function(e) {
            e.stopPropagation();
            var val = parseInt(slider.value);
            if (textVal) textVal.innerText = val + '%';
            if (tvStatesMap[tvId]) tvStatesMap[tvId].volume = val;
            
            clearTimeout(volumeTimeout);
            volumeTimeout = setTimeout(function() {
                updateTVState({
                    targetScope: 'single',
                    tvId: tvId,
                    action: 'volume',
                    volume: val
                });
            }, 150);
        });
    }

    return card;
}

function updateUIStateForCurrentScope() {
    var state = tvStatesMap[currentTvId] || { url: "", playing: false, time: 0, volume: 30 };
    var scopeTagText = "";
    var targetPrefix = _L('ui_target_prefix', 'TARGET');

    if (currentScope === 'all') {
        scopeTagText = targetPrefix + ": " + _L('ui_scope_all', 'SYNC ALL 7 TVs');
    } else if (currentScope === 'group') {
        var gName = (currentGroupId === 1) ? _L('ui_scope_g1', 'LEFT BAR (TV 1-4)') : _L('ui_scope_g2', 'RIGHT BAR (TV 5-7)');
        scopeTagText = targetPrefix + ": " + gName;
    } else {
        scopeTagText = targetPrefix + ": TV #" + currentTvId;
    }

    document.getElementById('scope-tag').innerText = scopeTagText;
    document.getElementById('preview-monitor-label').innerHTML = `<i class="fa-solid fa-tv"></i> PROGRAM MONITOR — FOCUSED: TV #${currentTvId}`;

    // Monitor Preview & Input Updates
    var iframe = document.getElementById('preview-iframe');
    var placeholder = document.getElementById('preview-placeholder');
    var badge = document.getElementById('preview-status-badge');
    var input = document.getElementById('custom-url-input');

    var isLive = state.playing && state.url && state.url !== "";
    var isPaused = !state.playing && state.url && state.url !== "";

    if (isLive || isPaused) {
        var videoId = getYoutubeId(state.url);
        if (videoId) {
            var embedUrl = "https://www.youtube-nocookie.com/embed/" + videoId + "?autoplay=1&mute=1&controls=0&enablejsapi=1";
            if (iframe.src !== embedUrl) {
                iframe.src = embedUrl;
            }
            iframe.style.display = 'block';
            if (placeholder) placeholder.style.display = 'none';
        }
        if (input && state.url) {
            input.value = state.url;
        }

        if (isLive) {
            badge.className = "monitor-status-badge badge-live";
            badge.innerHTML = `<span class="status-dot dot-live"></span> ${_L('ui_status_playing', 'LIVE / PLAYING')}`;
            document.getElementById('action-pause').style.display = 'flex';
            document.getElementById('action-resume').style.display = 'none';
        } else {
            badge.className = "monitor-status-badge badge-paused";
            badge.innerHTML = `<span class="status-dot dot-paused"></span> ${_L('ui_status_paused', 'PAUSED')}`;
            document.getElementById('action-pause').style.display = 'none';
            document.getElementById('action-resume').style.display = 'flex';
        }
    } else {
        iframe.src = "about:blank";
        iframe.style.display = 'none';
        if (placeholder) placeholder.style.display = 'flex';
        if (input) input.value = "";

        badge.className = "monitor-status-badge badge-off";
        badge.innerHTML = `<span class="status-dot dot-off"></span> ${_L('ui_status_off', 'OFF / IDLE')}`;
        document.getElementById('action-pause').style.display = 'none';
        document.getElementById('action-resume').style.display = 'none';
    }

    var volumeSlider = document.getElementById('volume-slider');
    if (volumeSlider) {
        volumeSlider.value = state.volume || 30;
        document.getElementById('volume-val').innerText = (state.volume || 30) + '%';
    }
}

// Oynatma Buton Dinleyicileri
document.getElementById('play-custom-btn').addEventListener('click', function() {
    var url = document.getElementById('custom-url-input').value.trim();
    if (url === '') return;
    
    updateTVState({
        action: 'play',
        url: url
    });
});

document.getElementById('action-pause').addEventListener('click', function() {
    updateTVState({ action: 'pause' });
});

document.getElementById('action-resume').addEventListener('click', function() {
    updateTVState({ action: 'resume' });
});

document.getElementById('action-stop').addEventListener('click', function() {
    document.getElementById('custom-url-input').value = "";
    updateTVState({ action: 'stop' });
});

// Ses Ayarı (Throttled)
var volumeTimeout;
var volumeSlider = document.getElementById('volume-slider');
volumeSlider.addEventListener('input', function() {
    var val = volumeSlider.value;
    document.getElementById('volume-val').innerText = val + '%';
    
    clearTimeout(volumeTimeout);
    volumeTimeout = setTimeout(function() {
        updateTVState({
            action: 'volume',
            volume: parseInt(val)
        });
    }, 150);
});

// Sunucuya Durum Güncelleme İsteği Gönderme / Web İnceleme Fallback
function updateTVState(data) {
    data.targetScope = currentScope;
    data.tvId = currentTvId;
    data.groupId = currentGroupId;
    data.locationKey = currentLocationKey;

    if (typeof GetParentResourceName !== 'undefined') {
        fetch(`https://${GetParentResourceName()}/updateState`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify(data)
        });
    } else {
        console.log("[Web Master Control Action]:", data);
        var targetTvIds = [];
        if (currentScope === 'all') {
            targetTvIds = [1, 2, 3, 4, 5, 6, 7];
        } else if (currentScope === 'group') {
            targetTvIds = (currentGroupId === 1) ? [1, 2, 3, 4] : [5, 6, 7];
        } else {
            targetTvIds = [currentTvId];
        }

        targetTvIds.forEach(function(tId) {
            if (!tvStatesMap[tId]) tvStatesMap[tId] = { url: "", playing: false, time: 0, volume: 30 };
            if (data.action === 'play') {
                tvStatesMap[tId].url = data.url;
                tvStatesMap[tId].playing = true;
            } else if (data.action === 'stop') {
                tvStatesMap[tId].url = "";
                tvStatesMap[tId].playing = false;
            } else if (data.action === 'pause') {
                tvStatesMap[tId].playing = false;
            } else if (data.action === 'resume') {
                tvStatesMap[tId].playing = true;
            } else if (data.action === 'volume') {
                tvStatesMap[tId].volume = data.volume;
            }
        });

        renderTvMatrix();
        updateUIStateForCurrentScope();
    }
}
