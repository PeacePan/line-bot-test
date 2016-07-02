module.exports = (function() {
    // var xmlhttp = new XMLHttpRequest();
    // xmlhttp.onreadystatechange = function() {
    //     // 0: request not initialized
    //     // 1: server connection established
    //     // 2: request received
    //     // 3: processing request
    //     // 4: request finished and response is ready
    //     if (xmlhttp.status === 200) {
    //         if (xmlhttp.readyState === 0) {
    //
    //         } else if (xmlhttp.readyState === 1) {
    //
    //         } else if (xmlhttp.readyState === 2) {
    //
    //         } else if (xmlhttp.readyState === 3) {
    //
    //         } else if (xmlhttp.readyState === 4) {
    //             console.log(xmlhttp);
    //             document.getElementById('demo').innerHTML = xmlhttp.responseText;
    //         } else {
    //             // Unknown Status
    //         }
    //     } else {
    //
    //     }
    // };
    // xmlhttp.open('GET', 'http://www.google.com', false);
    // xmlhttp.send();

    var pluginAlias = 'LineConnect';

    return {
       login: function(success, failure) {
           cordova.exec(success, failure, pluginAlias, 'login', []);
       },
       logout: function(success, failure) {
           cordova.exec(success, failure, pluginAlias, 'logout', []);
       },
       getUserProfile: function(success, failure) {
           cordova.exec(success, failure, pluginAlias, 'getUserProfile', []);
       }
    };
})();
