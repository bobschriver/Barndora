function onMessage(evt)
{
	var json = evt.data
	


	var parse_json = eval('(' + json + ')')


	var audio = document.getElementById('player')
	audio.src = parse_json.streaming_url

	var band_url = document.getElementById('band_url')
	band_url.href = parse_json.band_url
	band_url.innerHTML = parse_json.band_name

	var album_url = document.getElementById('album_url')
	album_url.href = parse_json.album_url
	album_url.innerHTML = parse_json.album_name

	var track_url = document.getElementById('track_url')
	track_url.href = parse_json.band_url + parse_json.url
	track_url.innerHTML = parse_json.title

	var track_art = document.getElementById('art_img')
	track_art.src = parse_json.large_art_url
}

function onOpen(evt)
{
	var input = document.getElementById('tags')
	input.value = 'rock,California'
	
	submit_tags()
}

function init()
{
	websocket = new WebSocket("ws://totoro.csh.rit.edu:2015/"); 
	websocket.onopen = function(evt) { onOpen(evt) }; 
	//websocket.onclose = function(evt) { onClose(evt) }; 
	websocket.onmessage = function(evt) { onMessage(evt) }; 
	//websocket.onerror = function(evt) { onError(evt) };
}

function add_tag()
{
}

function next()
{
	websocket.send("next")
}

function submit_tags()
{
	var input = document.getElementById('tags')

	var tags = input.value

	websocket.send(tags)
	next()
}

