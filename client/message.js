
function set_message(message , delay , type)
{
	message_label = document.getElementById('message_label')
	message_label.innerHTML = message

	message_div = document.getElementById('message_div')

	if(type == 'normal')
	{
		message_div.className = 'normal_message'
	}
	else if(type == 'warning')
	{
		message_div.className = 'warning_message'
	}
	else if(type == 'error')
	{
		message_div.className = 'error_message'
	}
	
	if(delay != 0)
	{
		setTimeout("hide_message()" , delay * 1000)
	}
}

function hide_message()
{
	message_div = document.getElementById('message_div')
	message_div.className = 'hidden_message'
}
