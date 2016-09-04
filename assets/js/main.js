$(function(){
    setup_commit_review_links();
    setup_ticket_review_links();
});

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
    $('#tickets-list .ac a.btn').click(function (e) {
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