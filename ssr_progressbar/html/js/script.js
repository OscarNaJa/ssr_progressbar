var cancelledTimer = null;
var progressRaf = null;

$('document').ready(function() {
    MythicProgBar = {};

    const $container = $('.progress-container');
    const $root = $('#seg-progress');
    const $label = $('#progress-label');
    const $actionLabel = $('#action-label');
    const $segments = $('#progress-segments .segment');
    const totalSegments = $segments.length;
    let currentState = 'idle';
    let lastLabel = '';
    let lastFilledCount = -1;
    let lastActiveIndex = -1;

    function stopProgressAnimation() {
        if (progressRaf) {
            cancelAnimationFrame(progressRaf);
            progressRaf = null;
        }
    }

    function setState(state) {
        if (currentState === state) {
            return;
        }

        $root.removeClass('is-cancelled is-complete');
        currentState = state;

        if (state === 'cancelled') {
            $root.addClass('is-cancelled');
            if (lastLabel !== 'ยกเลิก') {
                $label.text('ยกเลิก');
                lastLabel = 'ยกเลิก';
            }
            return;
        }

        if (state === 'complete') {
            $root.addClass('is-complete');
        }
    }


    function applyColorConfig(colors) {
        const rootStyle = document.documentElement.style;
        const progressBarColor = colors && colors.progressBar ? colors.progressBar : '#18a4ff';
        const percentTextColor = colors && colors.percentText ? colors.percentText : '#f2f5f8';
        const boxBackgroundColor = colors && colors.boxBackground ? colors.boxBackground : 'rgba(7, 11, 18, 0.97)';
        const boxBorderColor = colors && colors.boxBorder ? colors.boxBorder : 'rgba(255, 255, 255, 0.08)';
        const boxInnerBorderColor = colors && colors.boxInnerBorder ? colors.boxInnerBorder : 'rgba(255, 255, 255, 0.03)';
        const segmentEmptyColor = colors && colors.segmentEmpty ? colors.segmentEmpty : 'rgba(235, 241, 255, 0.42)';
        const actionLabelColor = colors && colors.actionLabel ? colors.actionLabel : '#f2f5f8';

        rootStyle.setProperty('--progress-filled-color', progressBarColor);
        rootStyle.setProperty('--progress-active-glow', progressBarColor);
        rootStyle.setProperty('--progress-percent-color', percentTextColor);
        rootStyle.setProperty('--progress-box-background', boxBackgroundColor);
        rootStyle.setProperty('--progress-box-border', boxBorderColor);
        rootStyle.setProperty('--progress-box-inner-border', boxInnerBorderColor);
        rootStyle.setProperty('--progress-segment-empty', segmentEmptyColor);
        rootStyle.setProperty('--progress-action-label-color', actionLabelColor);
    }


    function playSound(path, volume) {
        if (!path) {
            return;
        }

        const normalizedVolume = Math.max(0, Math.min(1, Number.isFinite(volume) ? volume : 0.35));
        const audio = new Audio(path);
        audio.volume = normalizedVolume;
        audio.play().catch(function() {
            // Ignore audio errors (e.g., missing file) to avoid breaking UI.
        });
    }

    function playProgressSound(sounds, type) {
        if (!sounds || !sounds.enabled) {
            return;
        }

        if (type === 'complete') {
            playSound(sounds.completeMp3, sounds.volume);
            return;
        }

        if (type === 'cancel') {
            playSound(sounds.cancelMp3, sounds.volume);
        }
    }


    function updateActionLabel(text) {
        const labelText = text && text.trim ? text.trim() : '';

        if (labelText.length > 0) {
            $actionLabel.text(labelText);
            $actionLabel.show();
            return;
        }

        $actionLabel.text('');
        $actionLabel.hide();
    }

    function updateProgress(percentValue) {
        const safePercent = Math.max(0, Math.min(100, percentValue));
        const filledCount = Math.max(0, Math.min(totalSegments, Math.ceil((safePercent / 100) * totalSegments)));
        const activeIndex = Math.max(0, Math.min(totalSegments - 1, filledCount - 1));
        const nextLabel = Math.floor(safePercent) + '%';

        setState('running');

        if (lastLabel !== nextLabel) {
            $label.text(nextLabel);
            lastLabel = nextLabel;
        }

        if (lastFilledCount === filledCount && lastActiveIndex === activeIndex) {
            return;
        }

        lastFilledCount = filledCount;
        lastActiveIndex = activeIndex;

        for (let index = 0; index < totalSegments; index++) {
            const segment = $segments.eq(index);
            segment.toggleClass('filled', index < filledCount);
            segment.toggleClass('active', index === activeIndex && filledCount > 0);
        }
    }

    MythicProgBar.Progress = function(data) {
        const sounds = data.sounds || null;
        clearTimeout(cancelledTimer);
        stopProgressAnimation();
        applyColorConfig(data.colors);
        updateActionLabel(data.label || "");
        currentState = 'idle';
        lastLabel = '';
        lastFilledCount = -1;
        lastActiveIndex = -1;
        updateProgress(0);

        $container.fadeIn('fast', function() {
            const duration = Math.max(parseInt(data.duration, 10) || 0, 1);
            const start = performance.now();

            function frame(now) {
                const elapsed = now - start;
                const percent = (elapsed / duration) * 100;
                updateProgress(percent);

                if (elapsed < duration) {
                    progressRaf = requestAnimationFrame(frame);
                    return;
                }

                updateProgress(100);
                setState('complete');
                playProgressSound(sounds, 'complete');
                stopProgressAnimation();

                setTimeout(function() {
                    $container.fadeOut('fast', function() {
                        updateActionLabel('');
                        $.post('https://ssr_progressbar/actionFinish', JSON.stringify({}));
                    });
                }, 320);
            }

            progressRaf = requestAnimationFrame(frame);
        });
    };

    MythicProgBar.ProgressCancel = function(data) {
        const sounds = data && data.sounds ? data.sounds : null;
        stopProgressAnimation();
        playProgressSound(sounds, 'cancel');
        setState('cancelled');

        cancelledTimer = setTimeout(function () {
            $container.fadeOut('fast', function() {
                currentState = 'idle';
                lastLabel = '';
                lastFilledCount = -1;
                lastActiveIndex = -1;
                updateProgress(0);
                updateActionLabel('');
                $.post('https://ssr_progressbar/actionCancel', JSON.stringify({}));
            });
        }, 850);
    };

    MythicProgBar.CloseUI = function() {
        stopProgressAnimation();
        updateActionLabel('');
        $container.fadeOut('fast');
    };

    window.addEventListener('message', function(event) {
        switch(event.data.action) {
            case 'mythic_progress':
                MythicProgBar.Progress(event.data);
                break;
            case 'mythic_progress_cancel':
                MythicProgBar.ProgressCancel(event.data);
                break;
        }
    });
});
