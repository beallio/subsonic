<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="iso-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html><head>
    <%@ include file="head.jsp" %>
    <%@ include file="jquery.jsp" %>
    <link type="text/css" rel="stylesheet" href="<c:url value="/script/webfx/luna.css"/>">
    <script type="text/javascript" src="<c:url value="/dwr/interface/nowPlayingService.js"/>"></script>
    <script type="text/javascript" src="<c:url value="/dwr/interface/playQueueService.js"/>"></script>
    <script type="text/javascript" src="<c:url value="/dwr/interface/playlistService.js"/>"></script>
    <script type="text/javascript" src="<c:url value="/dwr/engine.js"/>"></script>
    <script type="text/javascript" src="<c:url value="/dwr/util.js"/>"></script>
    <script type="text/javascript" src="<c:url value="/script/jwplayer-5.10.min.js"/>"></script>
    <script type="text/javascript" src="<c:url value="/script/cast_sender-v1.js"/>"></script>
    <%@ include file="playQueueCast.jsp" %>
    <link type="text/css" rel="stylesheet" href="<c:url value="/script/webfx/luna.css"/>">
    <style type="text/css">
        .ui-slider .ui-slider-handle {
            width: 11px;
            height: 11px;
            cursor: pointer;
        }
        .ui-slider a {
            outline:none;
        }
        .ui-slider {
            cursor: pointer;
        }
    </style>
</head>

<body class="bgcolor2 playlistframe" onload="init()">

<script type="text/javascript" language="javascript">
    var songs = null;
    var currentAlbumUrl = null;
    var currentStreamUrl = null;
    var repeatEnabled = false;
    var CastPlayer = new CastPlayer();

    function init() {
        dwr.engine.setErrorHandler(null);
        startTimer();

        $("#dialog-select-playlist").dialog({resizable: true, height: 220, autoOpen: false,
            buttons: {
                "<fmt:message key="common.cancel"/>": function() {
                    $(this).dialog("close");
                }
            }});

        <c:if test="${model.player.web}">createPlayer();</c:if>
        getPlayQueue();
    }

    function startTimer() {
        <!-- Periodically check if the current song has changed. -->
        nowPlayingService.getNowPlayingForCurrentPlayer(nowPlayingCallback);
        setTimeout("startTimer()", 10000);
    }

    function nowPlayingCallback(nowPlayingInfo) {
        if (nowPlayingInfo != null && nowPlayingInfo.streamUrl != currentStreamUrl) {
            getPlayQueue();
            if (currentAlbumUrl != nowPlayingInfo.albumUrl && top.main.updateNowPlaying) {
                top.main.location.replace("nowPlaying.view?");
                currentAlbumUrl = nowPlayingInfo.albumUrl;
            }
        <c:if test="${not model.player.web}">
            currentStreamUrl = nowPlayingInfo.streamUrl;
            updateCurrentImage();
        </c:if>
        }
    }

    function createPlayer() {
        jwplayer("jwplayer").setup({
            flashplayer: "<c:url value="/flash/jw-player-5.10.swf"/>",
            height: 24,
            width: 350,
            controlbar: "bottom",
            backcolor:"<spring:theme code="backgroundColor"/>",
            frontcolor:"<spring:theme code="textColor"/>"
        });

        jwplayer().onComplete(function() {onNext(repeatEnabled)});
    }

    function getPlayQueue() {
        playQueueService.getPlayQueue(playQueueCallback);
    }

    function onClear() {
        var ok = true;
    <c:if test="${model.partyMode}">
        ok = confirm("<fmt:message key="playlist.confirmclear"/>");
    </c:if>
        if (ok) {
            playQueueService.clear(playQueueCallback);
        }
    }
    function onStart() {
        playQueueService.start(playQueueCallback);
    }
    function onStop() {
        playQueueService.stop(playQueueCallback);
    }
    function onGain(gain) {
        playQueueService.setGain(gain);
    }
    function onJukeboxVolumeChanged() {
        var value = parseInt($("#jukeboxVolume").slider("option", "value"));
        onGain(value / 100);
    }
    function onCastVolumeChanged() {
        var value = parseInt($("#castVolume").slider("option", "value"));
        CastPlayer.setCastVolume(value / 100, false);
    }
    function onSkip(index) {
    <c:choose>
    <c:when test="${model.player.web}">
        skip(index);
    </c:when>
    <c:otherwise>
        currentStreamUrl = songs[index].streamUrl;
        playQueueService.skip(index, playQueueCallback);
    </c:otherwise>
    </c:choose>
    }
    function onNext(wrap) {
        var index = parseInt(getCurrentSongIndex()) + 1;
        if (wrap) {
            index = index % songs.length;
        }
        skip(index);
    }
    function onPrevious() {
        skip(parseInt(getCurrentSongIndex()) - 1);
    }
    function onPlay(id) {
        playQueueService.play(id, playQueueCallback);
    }
    function onPlayPlaylist(id, index) {
        index = index || 0;
        playQueueService.playPlaylist(id, index, playQueueCallback);
    }
    function onPlayStarred() {
        playQueueService.playStarred(playQueueCallback);
    }
    function onPlayRandom(id, count) {
        playQueueService.playRandom(id, count, playQueueCallback);
    }
    function onAdd(id) {
        playQueueService.add(id, playQueueCallback);
    }
    function onAddNext(id) {
        playQueueService.addAt(id, getCurrentSongIndex() + 1, playQueueCallback);
    }
    function onShuffle() {
        playQueueService.shuffle(playQueueCallback);
    }
    function onStar(index) {
        playQueueService.toggleStar(index, playQueueCallback);
    }
    function onRemove(index) {
        playQueueService.remove(index, playQueueCallback);
    }
    function onRemoveSelected() {
        var indexes = new Array();
        var counter = 0;
        for (var i = 0; i < songs.length; i++) {
            var index = i + 1;
            if ($("#songIndex" + index).is(":checked")) {
                indexes[counter++] = i;
            }
        }
        playQueueService.removeMany(indexes, playQueueCallback);
    }

    function onUp(index) {
        playQueueService.up(index, playQueueCallback);
    }
    function onDown(index) {
        playQueueService.down(index, playQueueCallback);
    }
    function onToggleRepeat() {
        playQueueService.toggleRepeat(playQueueCallback);
    }
    function onUndo() {
        playQueueService.undo(playQueueCallback);
    }
    function onSortByTrack() {
        playQueueService.sortByTrack(playQueueCallback);
    }
    function onSortByArtist() {
        playQueueService.sortByArtist(playQueueCallback);
    }
    function onSortByAlbum() {
        playQueueService.sortByAlbum(playQueueCallback);
    }
    function onSavePlaylist() {
        playlistService.createPlaylistForPlayQueue(function () {
            top.left.updatePlaylists();
            top.left.showAllPlaylists();
            $().toastmessage("showSuccessToast", "<fmt:message key="playlist.toast.saveasplaylist"/>");
        });
    }
    function onAppendPlaylist() {
        playlistService.getWritablePlaylists(playlistCallback);
    }
    function playlistCallback(playlists) {
        $("#dialog-select-playlist-list").empty();
        for (var i = 0; i < playlists.length; i++) {
            var playlist = playlists[i];
            $("<p class='dense'><b><a href='#' onclick='appendPlaylist(" + playlist.id + ")'>" + playlist.name + "</a></b></p>").appendTo("#dialog-select-playlist-list");
        }
        $("#dialog-select-playlist").dialog("open");
    }
    function appendPlaylist(playlistId) {
        $("#dialog-select-playlist").dialog("close");

        var mediaFileIds = new Array();
        for (var i = 0; i < songs.length; i++) {
            if ($("#songIndex" + (i + 1)).is(":checked")) {
                mediaFileIds.push(songs[i].id);
            }
        }
        playlistService.appendToPlaylist(playlistId, mediaFileIds, function (){
            top.left.updatePlaylists();
            $().toastmessage("showSuccessToast", "<fmt:message key="playlist.toast.appendtoplaylist"/>");
        });
    }

    function playQueueCallback(playQueue) {
        songs = playQueue.entries;
        repeatEnabled = playQueue.repeatEnabled;
        if ($("#start")) {
            $("#start").toggle(!playQueue.stopEnabled);
            $("#stop").toggle(playQueue.stopEnabled);
        }

        if ($("#toggleRepeat")) {
            var text = repeatEnabled ? "<fmt:message key="playlist.repeat_on"/>" : "<fmt:message key="playlist.repeat_off"/>";
            $("#toggleRepeat").html(text);
        }

        if (songs.length == 0) {
            $("#empty").show();
        } else {
            $("#empty").hide();
        }

        // Delete all the rows except for the "pattern" row
        dwr.util.removeAllRows("playlistBody", { filter:function(tr) {
            return (tr.id != "pattern");
        }});

        // Create a new set cloned from the pattern row
        for (var i = 0; i < songs.length; i++) {
            var song  = songs[i];
            var id = i + 1;
            dwr.util.cloneNode("pattern", { idSuffix:id });
            if ($("#trackNumber" + id)) {
                $("#trackNumber" + id).html(song.trackNumber);
            }
            if (song.starred) {
                $("#starSong" + id).attr("src", "<spring:theme code='ratingOnImage'/>");
            } else {
                $("#starSong" + id).attr("src", "<spring:theme code='ratingOffImage'/>");
            } 
            if ($("#currentImage" + id) && song.streamUrl == currentStreamUrl) {
                $("#currentImage" + id).show();
            }
            if ($("#title" + id)) {
                $("#title" + id).html(truncate(song.title));
                $("#title" + id).attr("title", song.title);
            }
            if ($("#titleUrl" + id)) {
                $("#titleUrl" + id).html(truncate(song.title));
                $("#titleUrl" + id).attr("title", song.title);
                $("#titleUrl" + id).click(function () {onSkip(this.id.substring(8) - 1)});
            }
            if ($("#album" + id)) {
                $("#album" + id).html(truncate(song.album));
                $("#album" + id).attr("title", song.album);
                $("#albumUrl" + id).attr("href", song.albumUrl);
            }
            if ($("#artist" + id)) {
                $("#artist" + id).html(truncate(song.artist));
                $("#artist" + id).attr("title", song.artist);
            }
            if ($("#genre" + id)) {
                $("#genre" + id).html(song.genre);
            }
            if ($("#year" + id)) {
                $("#year" + id).html(song.year);
            }
            if ($("#bitRate" + id)) {
                $("#bitRate" + id).html(song.bitRate);
            }
            if ($("#duration" + id)) {
                $("#duration" + id).html(song.durationAsString);
            }
            if ($("#format" + id)) {
                $("#format" + id).html(song.format);
            }
            if ($("#fileSize" + id)) {
                $("#fileSize" + id).html(song.fileSize);
            }

            $("#pattern" + id).addClass((i % 2 == 0) ? "bgcolor1" : "bgcolor2");

            // Note: show() method causes page to scroll to top.
            $("#pattern" + id).css("display", "table-row");
        }

        if (playQueue.sendM3U) {
            parent.frames.main.location.href="play.m3u?";
        }

        var jukeboxVolume = $("#jukeboxVolume");
        if (jukeboxVolume) {
            jukeboxVolume.slider("option", "value", Math.floor(playQueue.gain * 100));
        }

    <c:if test="${model.player.web}">
        triggerPlayer(playQueue.startPlayerAt);
    </c:if>
    }

    function triggerPlayer(startPlayerAt) {
        if (startPlayerAt != -1) {
            if (songs.length > startPlayerAt) {
                skip(startPlayerAt);
            }
        }
        updateCurrentImage();
        if (songs.length == 0) {
            jwplayer().stop();
            jwplayer().load([]);
        }
    }

    function skip(index, position) {
        if (index < 0 || index >= songs.length) {
            return;
        }

        var song = songs[index];
        currentStreamUrl = song.streamUrl;
        updateCurrentImage();

        if (CastPlayer.castSession) {
            CastPlayer.loadCastMedia(song, position);
        } else {
            jwplayer().load({
                file: song.streamUrl,
                provider: song.format == "aac" || song.format == "m4a" ? "video" : "sound",
                duration: song.duration
            });
            jwplayer().play();
            console.log(song.streamUrl);
        }

        <c:if test="${model.notify}">
        showNotification(song);
        </c:if>
    }

    function showNotification(song) {
        if (!("Notification" in window)) {
            return;
        }
        if (Notification.permission === "granted") {
            createNotification(song);
        }
        else if (Notification.permission !== 'denied') {
            Notification.requestPermission(function (permission) {
                Notification.permission = permission;
                if (permission === "granted") {
                    createNotification(song);
                }
            });
        }
    }

    function createNotification(song) {
        var n = new Notification(song.title, {
            tag: "subsonic",
            body: song.artist + " - " + song.album,
            icon: "coverArt.view?id=" + song.id + "&size=110"
        });
        n.onshow = function() {
            setTimeout(function() {n.close()}, 5000);
        }
    }

    function updateCurrentImage() {
        for (var i = 0; i < songs.length; i++) {
            var song  = songs[i];
            var id = i + 1;
            var image = $("#currentImage" + id);

            if (image) {
                if (song.streamUrl == currentStreamUrl) {
                    image.show();
                } else {
                    image.hide();
                }
            }
        }
    }

    function getCurrentSongIndex() {
        for (var i = 0; i < songs.length; i++) {
            if (songs[i].streamUrl == currentStreamUrl) {
                return i;
            }
        }
        return -1;
    }

    function truncate(s) {
        if (s == null) {
            return s;
        }
        var cutoff = ${model.visibility.captionCutoff};

        if (s.length > cutoff) {
            return s.substring(0, cutoff) + "...";
        }
        return s;
    }

    <!-- actionSelected() is invoked when the users selects from the "More actions..." combo box. -->
    function actionSelected(id) {
        var selectedIndexes = getSelectedIndexes();
        if (id == "top") {
            return;
        } else if (id == "savePlaylist") {
            onSavePlaylist();
        } else if (id == "downloadPlaylist") {
            location.href = "download.view?player=${model.player.id}";
        } else if (id == "sharePlaylist") {
            parent.frames.main.location.href = "createShare.view?player=${model.player.id}&" + getSelectedIndexes();
        } else if (id == "sortByTrack") {
            onSortByTrack();
        } else if (id == "sortByArtist") {
            onSortByArtist();
        } else if (id == "sortByAlbum") {
            onSortByAlbum();
        } else if (id == "selectAll") {
            selectAll(true);
        } else if (id == "selectNone") {
            selectAll(false);
        } else if (id == "removeSelected") {
            onRemoveSelected();
        } else if (id == "download" && selectedIndexes != "") {
            location.href = "download.view?player=${model.player.id}&" + selectedIndexes;
        } else if (id == "appendPlaylist" && selectedIndexes != "") {
            onAppendPlaylist();
        }
        $("#moreActions").prop("selectedIndex", 0);
    }

    function getSelectedIndexes() {
        var result = "";
        for (var i = 0; i < songs.length; i++) {
            if ($("#songIndex" + (i + 1)).is(":checked")) {
                result += "i=" + i + "&";
            }
        }
        return result;
    }

    function selectAll(b) {
        for (var i = 0; i < songs.length; i++) {
            if (b) {
                $("#songIndex" + (i + 1)).attr("checked", "checked");
            } else {
                $("#songIndex" + (i + 1)).removeAttr("checked");
            }
        }
    }

</script>

<div class="bgcolor2" style="position:fixed; top:0; width:100%;padding-top:0.5em">
    <table style="white-space:nowrap;">
        <tr style="white-space:nowrap;">
            <c:if test="${model.user.settingsRole and fn:length(model.players) gt 1}">
                <td style="padding-right: 5px"><select name="player" onchange="location='playQueue.view?player=' + options[selectedIndex].value;">
                    <c:forEach items="${model.players}" var="player">
                        <option ${player.id eq model.player.id ? "selected" : ""} value="${player.id}">${player.shortDescription}</option>
                    </c:forEach>
                </select></td>
            </c:if>
            <c:if test="${model.player.web}">
                <td>
                    <div id="flashPlayer" style="width:340px; height:24px;padding-right:10px">
                        <div id="jwplayer"><a href="http://www.adobe.com/go/getflashplayer" target="_blank"><fmt:message key="playlist.getflash"/></a></div>
                    </div>
                    <div id="castPlayer" style="display: none">
                        <div style="float:left">
                            <img id="castPlay" src="<spring:theme code="castPlayImage"/>" onclick="CastPlayer.playCast()" style="cursor:pointer">
                            <img id="castPause" src="<spring:theme code="castPauseImage"/>" onclick="CastPlayer.pauseCast()" style="cursor:pointer; display:none">
                            <img id="castMuteOn" src="<spring:theme code="volumeImage"/>" onclick="CastPlayer.castMuteOn()" style="cursor:pointer">
                            <img id="castMuteOff" src="<spring:theme code="muteImage"/>" onclick="CastPlayer.castMuteOff()" style="cursor:pointer; display:none">
                        </div>
                        <div style="float:left">
                            <div id="castVolume" style="width:80px;height:4px;margin-left:10px;margin-right:10px;margin-top:8px"></div>
                            <script type="text/javascript">
                                $("#castVolume").slider({max: 100, value: 50, animate: "fast", range: "min"});
                                $("#castVolume").on("slidestop", onCastVolumeChanged);
                            </script>
                        </div>
                    </div>
                </td>
                <td>
                    <img id="castOn" src="<spring:theme code="castIdleImage"/>" onclick="CastPlayer.launchCastApp()" style="cursor:pointer; display:none">
                    <img id="castOff" src="<spring:theme code="castActiveImage"/>" onclick="CastPlayer.stopCastApp()" style="cursor:pointer; display:none">
                </td>
            </c:if>

            <c:if test="${model.user.streamRole and not model.player.web}">
                <td>
                    <img id="start" src="<spring:theme code="castPlayImage"/>" onclick="onStart()" style="cursor:pointer">
                    <img id="stop" src="<spring:theme code="castPauseImage"/>" onclick="onStop()" style="cursor:pointer; display:none">
                </td>
            </c:if>

            <c:if test="${model.player.jukebox}">
                <td style="white-space:nowrap;">
                    <img src="<spring:theme code="volumeImage"/>" alt="">
                </td>
                <td style="white-space:nowrap;">
                    <div id="jukeboxVolume" style="width:80px;height:4px"></div>
                    <script type="text/javascript">
                        $("#jukeboxVolume").slider({max: 100, value: 50, animate: "fast", range: "min"});
                        $("#jukeboxVolume").on("slidestop", onJukeboxVolumeChanged);
                    </script>
                </td>
            </c:if>

            <c:if test="${model.player.web}">
                <td><span class="header">
                    <a href="javascript:void(0)" onclick="onPrevious()"><img src="<spring:theme code="backImage"/>" alt=""></a></span>
                </td>
                <td><span class="header">
                    <a href="javascript:void(0)" onclick="onNext(false)"><img src="<spring:theme code="forwardImage"/>" alt=""></a></span>
                </td>
            </c:if>

            <td style="white-space:nowrap;"><span class="header"><a href="javascript:void(0)" onclick="onClear()"><fmt:message key="playlist.clear"/></a></span> |</td>
            <td style="white-space:nowrap;"><span class="header"><a href="javascript:void(0)" onclick="onShuffle()"><fmt:message key="playlist.shuffle"/></a></span> |</td>

            <c:if test="${model.player.web or model.player.jukebox or model.player.external}">
                <td style="white-space:nowrap;"><span class="header"><a href="javascript:void(0)" onclick="onToggleRepeat()"><span id="toggleRepeat"><fmt:message key="playlist.repeat_on"/></span></a></span>  |</td>
            </c:if>

            <td style="white-space:nowrap;"><span class="header"><a href="javascript:void(0)" onclick="onUndo()"><fmt:message key="playlist.undo"/></a></span>  |</td>

            <c:if test="${model.user.settingsRole}">
                <td style="white-space:nowrap;"><span class="header"><a href="playerSettings.view?id=${model.player.id}" target="main"><fmt:message key="playlist.settings"/></a></span>  |</td>
            </c:if>

            <td style="white-space:nowrap;"><select id="moreActions" onchange="actionSelected(this.options[selectedIndex].id)">
                <option id="top" selected="selected"><fmt:message key="playlist.more"/></option>
                <optgroup label="<fmt:message key="playlist.more.playlist"/>">
                    <option id="savePlaylist"><fmt:message key="playlist.save"/></option>
                    <c:if test="${model.user.downloadRole}">
                    <option id="downloadPlaylist"><fmt:message key="common.download"/></option>
                    </c:if>
                    <c:if test="${model.user.shareRole}">
                    <option id="sharePlaylist"><fmt:message key="main.more.share"/></option>
                    </c:if>
                    <option id="sortByTrack"><fmt:message key="playlist.more.sortbytrack"/></option>
                    <option id="sortByAlbum"><fmt:message key="playlist.more.sortbyalbum"/></option>
                    <option id="sortByArtist"><fmt:message key="playlist.more.sortbyartist"/></option>
                </optgroup>
                <optgroup label="<fmt:message key="playlist.more.selection"/>">
                    <option id="selectAll"><fmt:message key="playlist.more.selectall"/></option>
                    <option id="selectNone"><fmt:message key="playlist.more.selectnone"/></option>
                    <option id="removeSelected"><fmt:message key="playlist.remove"/></option>
                    <c:if test="${model.user.downloadRole}">
                        <option id="download"><fmt:message key="common.download"/></option>
                    </c:if>
                    <option id="appendPlaylist"><fmt:message key="playlist.append"/></option>
                </optgroup>
            </select>
            </td>

        </tr></table>
</div>

<div style="height:3.2em"></div>

<p id="empty"><em><fmt:message key="playlist.empty"/></em></p>

<table style="border-collapse:collapse;white-space:nowrap;">
    <tbody id="playlistBody">
        <tr id="pattern" style="display:none;margin:0;padding:0;border:0">
            <td style="padding-left:0.5em;padding-right:0.5em"><a href="javascript:void(0)">
                <img id="starSong" onclick="onStar(this.id.substring(8) - 1)" src="<spring:theme code="ratingOffImage"/>"
                     alt="" title=""></a></td>
            <td><a href="javascript:void(0)">
                <img id="removeSong" onclick="onRemove(this.id.substring(10) - 1)" src="<spring:theme code="removeImage"/>"
                     alt="<fmt:message key="playlist.remove"/>" title="<fmt:message key="playlist.remove"/>"></a></td>
            <td><a href="javascript:void(0)">
                <img id="up" onclick="onUp(this.id.substring(2) - 1)" src="<spring:theme code="upImage"/>"
                     alt="<fmt:message key="playlist.up"/>" title="<fmt:message key="playlist.up"/>"></a></td>
            <td><a href="javascript:void(0)">
                <img id="down" onclick="onDown(this.id.substring(4) - 1)" src="<spring:theme code="downImage"/>"
                     alt="<fmt:message key="playlist.down"/>" title="<fmt:message key="playlist.down"/>"></a></td>

            <td style="padding-left: 0.5em"><input type="checkbox" class="checkbox" id="songIndex"></td>
            <td style="padding-right:0.25em"></td>

            <c:if test="${model.visibility.trackNumberVisible}">
                <td style="padding-right:0.5em;text-align:right"><span class="detail" id="trackNumber">1</span></td>
            </c:if>

            <td style="padding-right:1.25em">
                <img id="currentImage" src="<spring:theme code="currentImage"/>" alt="" style="display:none;padding-right: 0.5em">
                <c:choose>
                    <c:when test="${model.player.externalWithPlaylist}">
                        <span id="title" class="songTitle">Title</span>
                    </c:when>
                    <c:otherwise>
                        <span class="songTitle"><a id="titleUrl" href="javascript:void(0)">Title</a></span>
                    </c:otherwise>
                </c:choose>
            </td>

            <c:if test="${model.visibility.albumVisible}">
                <td style="padding-right:1.25em"><a id="albumUrl" target="main"><span id="album" class="detail">Album</span></a></td>
            </c:if>
            <c:if test="${model.visibility.artistVisible}">
                <td style="padding-right:1.25em"><span id="artist" class="detail">Artist</span></td>
            </c:if>
            <c:if test="${model.visibility.genreVisible}">
                <td style="padding-right:1.25em"><span id="genre" class="detail">Genre</span></td>
            </c:if>
            <c:if test="${model.visibility.yearVisible}">
                <td style="padding-right:1.25em"><span id="year" class="detail">Year</span></td>
            </c:if>
            <c:if test="${model.visibility.formatVisible}">
                <td style="padding-right:1.25em"><span id="format" class="detail">Format</span></td>
            </c:if>
            <c:if test="${model.visibility.fileSizeVisible}">
                <td style="padding-right:1.25em;text-align:right;"><span id="fileSize" class="detail">Format</span></td>
            </c:if>
            <c:if test="${model.visibility.durationVisible}">
                <td style="padding-right:1.25em;text-align:right;"><span id="duration" class="detail">Duration</span></td>
            </c:if>
            <c:if test="${model.visibility.bitRateVisible}">
                <td style="padding-right:0.25em"><span id="bitRate" class="detail">Bit Rate</span></td>
            </c:if>
        </tr>
    </tbody>
</table>

<div id="dialog-select-playlist" title="<fmt:message key="main.addtoplaylist.title"/>" style="display: none;">
    <p><fmt:message key="main.addtoplaylist.text"/></p>
    <div id="dialog-select-playlist-list"></div>
</div>

</body></html>
