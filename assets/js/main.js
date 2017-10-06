$(function(){
    setup_confirm_buttons();
    setup_commit_review_links();
    setup_ticket_review_links();
});

function setup_confirm_buttons() {
    $('.delete-button').each(function(){
        $(this).click(function(e){
            if (! confirm('Really delete?')) return false;

            e.preventDefault();
            var el = $(this);
            $.ajax({
                url: el.attr('href'),
                error: function() { alert("Request failed") },
                success: function() {
                    el.closest('tr').fadeOut(1000, function(){ el.remove() });
                }
            });
        });
    });
}

function setup_commit_review_links() {
    $('#commits-list .info a.btn').click(function (e) {
        var el = $(this);
        e.preventDefault();

        $.ajax({
            url: el.attr('href'),
            error: function() { alert("Request failed") },
            success: function() {
                el  .toggleClass('btn-primary')
                    .toggleClass('btn-info')
                    .find('i')  .toggleClass('glyphicon-ok')
                                .toggleClass('glyphicon-question-sign')
                    .parents('li')
                        .toggleClass('a');
            }
        });
    });
}

function setup_ticket_review_links() {
    $('#tickets-list .ac a.btn:not(.delete-button)').click(function (e) {
        var el = $(this);
        e.preventDefault();

        $.ajax({
            url: el.attr('href'),
            error: function() { alert("Request failed") },
            success: function() {
                if ( el.hasClass('reviewed') ) {
                    el  .toggleClass('btn-default')
                        .toggleClass('btn-info')
                        .parents('tr')
                            .toggleClass('r');
                }
                else if ( el.hasClass('blocker') ) {
                    el  .toggleClass('btn-default')
                        .toggleClass('btn-danger')
                        .parents('tr')
                            .toggleClass('b');
                }
            }
        });
    });
}