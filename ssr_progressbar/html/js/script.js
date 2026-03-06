var cancelledTimer = null;
var progressRaf = null;

$('document').ready(function() {
    MythicProgBar = {};

    const $container = $('.progress-container');
    const $root = $('#seg-progress');
    const $label = $('#progress-label');
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
        clearTimeout(cancelledTimer);
        stopProgressAnimation();
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
                stopProgressAnimation();

                setTimeout(function() {
                    $container.fadeOut('fast', function() {
                        $.post(`https://${GetParentResourceName()}/actionFinish`, JSON.stringify({}));
                    });
                }, 320);
            }

            progressRaf = requestAnimationFrame(frame);
        });
    };

    MythicProgBar.ProgressCancel = function() {
        stopProgressAnimation();
        setState('cancelled');

        cancelledTimer = setTimeout(function () {
            $container.fadeOut('fast', function() {
                currentState = 'idle';
                lastLabel = '';
                lastFilledCount = -1;
                lastActiveIndex = -1;
                updateProgress(0);
                $.post(`https://${GetParentResourceName()}/actionCancel`, JSON.stringify({}));
            });
        }, 850);
    };

    MythicProgBar.CloseUI = function() {
        stopProgressAnimation();
        $container.fadeOut('fast');
    };

    window.addEventListener('message', function(event) {
        switch(event.data.action) {
            case 'mythic_progress':
                MythicProgBar.Progress(event.data);
                break;
            case 'mythic_progress_cancel':
                MythicProgBar.ProgressCancel();
                break;
        }
    });
});
