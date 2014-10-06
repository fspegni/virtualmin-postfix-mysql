var quotas = new Array();
function handleEditMailbox(id_list, id_text)
{
	//window.alert('ciao');
	var list = document.getElementById(id_list);
	var textbox = document.getElementById(id_text);
	if (list == null || textbox == null)
	{
		return;
	}

	if (quotas[list.value] == undefined)
	{
		textbox.value = '';
	}
	else
	{
		var quota = quotas[list.value];
		var MBquota = quota / (1024 * 1024);
	//	if (MBquota < 1)
	//	{
			MBquota = MBquota.toFixed(2);
	//	}
	//	else
	//	{
	//		MBquota.toFixed(0);
	//	}
		textbox.value = MBquota
	//	window.alert(quota);
	}
}

var aliases = new Array();
function handleChangeAlias(id_list, id_label)
{
	//window.alert('ciao');
	var list = document.getElementById(id_list);
	var textbox = document.getElementById(id_label);
	if (list == null || textbox == null)
	{
		return;
	}

	if (aliases[list.value] == undefined)
	{
		textbox.value = '';
	}
	else
	{
		textbox.value = aliases[list.value];
	}
}

function check_mailbox_create(form, local, pwd, pwd_rep, quota)
{
	var local_text = document.getElementById(local);
	//window.alert(local_text);
	if (local_text == undefined)
	{
		return true;
	}

	//window.alert(local_text.value);
	if (local_text.value == "" || 
		! local_text.value.match(/^[a-zA-Z0-9_\-.]+$/g))
	{
		window.alert("Indirizzo email non valido: " + local_text.value);
		return false;
	}

	var pwd_text = document.getElementById(pwd);
	var pwd_rep = document.getElementById(pwd_rep);

	if (pwd_text.value != pwd_rep.value)
	{
		window.alert("La password non corrisponde");
		return false;
	}

	var quota_text = document.getElementById(quota);
//	window.alert(quota_text);
	if (quota_text == undefined)
	{
		return true;
	}
//	window.alert(quota_text.value);
	// the quota is not a number
	if ( isNaN(quota_text.value))
	{
		window.alert("La quota dev'essere un numero");
		return false;
	}

	return true;
}

function check_alias_create(form, address, existing_address)
{
	var address_text = document.getElementById(address);
	//window.alert(address_text);
	if (address_text == undefined)
	{
		return true;
	}

	//window.alert(address_text.value);
	if (address_text.value == "" || 
		! address_text.value.match(/^[a-zA-Z0-9_\-.]+$/g))
	{
		window.alert("Indirizzo email non valido: " + address_text.value);
		return false;
	}

	var existing_text = document.getElementById(existing_address);

	if (existing_text == undefined)
	{
		return true;
	}
	if (existing_text.value == "")
	{
		window.alert("Non hai specificato l'indirizzo di destinazione dell'alias");
		return false;
	}

	if (! existing_text.value.match(/^[a-zA-Z0-9\-_.]+@[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_.]+$/))
	{
		window.alert("L'indirizzo di destinazione dell'alias non e` un indirizzo email valido:" + 
			existing_text.value);
		return false;
	}

	return true;

}

function check_mailbox_reset(list_id, quota_id)
{
	var list = document.getElementById(list_id);
	if (list == null)
	{
		return true;
	}

	// no alias selected
	if (list.value === "---")
	{
		return false;
	}

	var quota_text = document.getElementById(quota_id);
//	window.alert(quota_text);
	if (quota_text == undefined)
	{
		return true;
	}
//	window.alert(quota_text.value);
	// the quota is not a number
	if ( isNaN(quota_text.value))
	{
		window.alert("La quota dev'essere un numero");
		return false;
	}

	return true;
}

function check_alias_delete(list_id)
{
	var list = document.getElementById(list_id);
	if (list == null)
	{
		return true;
	}

	// no alias selected
	if (list.value === "---")
	{
		return false;
	}
	return true;
}
