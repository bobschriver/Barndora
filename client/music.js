function onMessage(evt)
{
	var json = evt.data

	var parse_json = eval('(' + json + ')')

	if(parse_json.message_type == 'error')
	{
		set_message(parse_json.error_message , 5 , 'error')
	}
	else if(parse_json.message_type == 'warning')
	{
		set_message(parse_json.warning_message , 5 , 'warning')
	}
	else if(parse_json.message_type == 'normal')
	{
		set_message(parse_json.message , 0 , 'normal')
	}
	else if(parse_json.message_type == 'track')
	{
		

		//First we need to create our old track in the list of div's
		add_prev_track()

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

		hide_message()

		enable_buttons()
		
		reset_rating()
	}

	
}

function disable_buttons()
{
	var next_button = document.getElementById('next_button')
	next_button.disabled = true

	var yup_button = document.getElementById('yup')
	yup_button.disabled = true

	var nope_button = document.getElementById('nope')
	nope_button.disabled = true
}

function enable_buttons()
{
	var next_button = document.getElementById('next_button')
	next_button.disabled = false

	var yup_button = document.getElementById('yup')
	yup_button.disabled = false

	var nope_button = document.getElementById('nope')
	nope_button.disabled = false

}

function add_tag(tag)
{
	var input = document.getElementById('tags')

	input.value += "," + tag

	submit_tags()
}


function add_prev_track()
{


	//Yeah this is a dumb way of skipping the first instance whatever
	if(typeof prev_track_id === 'undefined')
	{
		prev_track_id = 0
	}
	else
	{
	var prev_track_div = document.createElement('div')
	prev_track_div.id = 'prev_track_' + prev_track_id
	
	if(current_rating == 5)
	{
		prev_track_div.className = 'prev_track good'
	}
	else if(current_rating == 0)
	{
		prev_track_div.className = 'prev_track bad'
	}
	else
	{
		prev_track_div.className = 'prev_track normal'
	}


	var art = document.getElementById('art_img')
	var prev_art = art.cloneNode(true)
	prev_art.id = 'prev_art_' + prev_track_id
	prev_art.className = 'prev_art_img'

	var prev_track_info = document.createElement('div')
	prev_track_info.id = 'prev_track_links_' + prev_track_id 
	prev_track_info.className = 'prev_track_links'
	
	var prev_band = document.getElementById('band_url').cloneNode(true)
	prev_band.id = 'band_url_' + prev_track_id
	
	var prev_album = document.getElementById('album_url').cloneNode(true)
	prev_album.id = 'album_url_' + prev_track_id
	
	var prev_track = document.getElementById('track_url').cloneNode(true)
	prev_track.id = 'track_url_' + prev_track_id

	prev_track_info.appendChild(prev_band)
	prev_track_info.appendChild(document.createElement('br'))

	prev_track_info.appendChild(prev_album)
	prev_track_info.appendChild(document.createElement('br'))

	prev_track_info.appendChild(prev_track)
	prev_track_info.appendChild(document.createElement('br'))

	prev_track_div.appendChild(prev_art)
	prev_track_div.appendChild(prev_track_info)

	var prev_tracks = document.getElementById('prev_tracks')

	prev_tracks.insertBefore(prev_track_div , prev_tracks.firstChild)

	prev_track_id += 1
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
	disable_buttons()
	set_message('Getting next track...' , 0 , 'warning')
		
	var audio = document.getElementById('player')
	audio.pause()
	
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
	if(nope_depressed)
	{
		return;
	}

	
	if(yup_depressed)
	{
		yup_depressed = false
		button.className = 'yup'

		current_rating = 1
	}
	else
	{
		yup_depressed = true
		button.className = 'yup good'

		current_rating = 5
	}

}

function rate_nope(button)
{
	if(!nope_depressed)
	{
		nope_depressed = true
		button.className = 'nope bad'


		current_rating = 0
	
	
		next()
	}

	if(yup_depressed)
	{
		yup_depressed = false
		yup_button = document.getElementById('yup')
		yup_button.className = 'yup'
	}

}

function reset_rating()
{

	yup_button = document.getElementById('yup')
	nope_button = document.getElementById('nope')

	yup_depressed = false
	yup_button.className = 'yup'

	nope_depressed = false
	nope_button.className = 'nope'

	current_rating = 1
}
