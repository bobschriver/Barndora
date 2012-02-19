function onMessage(evt)
{
	var json = evt.data

	var parse_json = eval('(' + json + ')')

	if(parse_json.error_type != null)
	{
		set_message(parse_json.error_message , 5 , 'error')
	
		
	}
	else
	{
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

		reset()
	}

	
}

function onOpen(evt)
{
	hide_message()

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

 	set_message('Connecting to server...' , 0 , 'warning')	

	current_rating = 1
	yup_depressed = false
	nope_depressed = false
	message_recieved = false
}


function next()
{
	var command = "next" + ":" + current_rating
	websocket.send(command)
}

function submit_tags()
{
	var input = document.getElementById('tags')

	var tags = input.value

	var command = "tags" + ":" + tags

	websocket.send(command)
	next()
}



function rate_yup(button)
{
	if(yup_depressed)
	{
		yup_depressed = false
		button.className = 'yup_undepressed'

		current_rating = 1
	}
	else
	{
		yup_depressed = true
		button.className = 'yup_depressed'

		current_rating = 5
	}

	if(nope_depressed)
	{
		nope_depressed = false
		nope_button = document.getElementById('nope')
		nope_button.className = 'nope_undepressed'
	}
}

function rate_nope(button)
{
	if(nope_depressed)
	{
		nope_depressed = false
		button.className = 'nope_undepressed'

		current_rating = 1	
	}
	else
	{
		nope_depressed = true
		button.className = 'nope_depressed'


		current_rating = 0
	}

	if(yup_depressed)
	{
		yup_depressed = false
		yup_button = document.getElementById('yup')
		yup_button.className = 'yup_undepressed'
	}

	if(nope_depressed)
	{
		next()

	}

}

function reset()
{

	yup_button = document.getElementById('yup')
	nope_button = document.getElementById('nope')

	yup_depressed = false
	yup_button.className = 'yup_undepressed'

	nope_depressed = false
	nope_button.className = 'nope_undepressed'

	current_rating = 1
}
