function onMessage(evt)
{
	var url = evt.data
	
	
	var audio = document.getElementById('player')
	audio.src = url
}

function onOpen(evt)
{
	var input = document.getElementById('tags')
	input.value = 'rock'

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

