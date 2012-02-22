
function set_message(message , delay , type)
{
	message_label = document.getElementById('message_label')
	message_label.innerHTML = message

	message_div = document.getElementById('message_div')

	if(type == 'normal')
	{
		message_div.className = 'message normal'
	}
	else if(type == 'warning')
	{
		message_div.className = 'message warning'
	}
	else if(type == 'error')
	{
		message_div.className = 'message bad'
	}
	
	if(delay != 0)
	{
		setTimeout("hide_message()" , delay * 1000)
	}
}

function hide_message()
{

	reset_links()
	message_div = document.getElementById('message_div')
	message_div.className = 'hidden_message'

	message_label = document.getElementById('message_label')
	message_label.innerHTML = ""
}

function close_message()
{
	hide_message()
}

function reset_links()
{
	var about_link = document.getElementById('about_link')
	about_link.setAttribute('onclick' , 'get_about()')
	about_link.innerHTML = 'About'

	var tags_link = document.getElementById('tags_link')
	tags_link.setAttribute('onclick' , 'get_tags()')
	tags_link.innerHTML = 'Tags'

	var help_link = document.getElementById('help_link')
	help_link.setAttribute('onclick' , 'get_help()')
	help_link.innerHTML = 'Help'
}

function get_about()
{
	reset_links()

	var about_link = document.getElementById('about_link')
	about_link.setAttribute('onclick' , 'close_message()')
	about_link.innerHTML = 'Hide About'

	var command = 'about' + ':'
	websocket.send(command)
}

function get_tags()
{
	reset_links()

	var tags_link = document.getElementById('tags_link')
	tags_link.setAttribute('onclick' , 'close_message()')
	tags_link.innerHTML = 'Hide Tags'

	var command = 'get_tags' + ':'
	websocket.send(command)
}

function get_help()
{
	reset_links()

	var help_link = document.getElementById('help_link')
	help_link.setAttribute('onclick' , 'close_message()')
	help_link.innerHTML = 'Hide Help'

	var command = 'help' + ':'
	websocket.send(command)
}
