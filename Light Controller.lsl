integer count = 0;
integer hasPermission = FALSE;
float radius = 5;
integer randomRez = FALSE;
float speed = 10;


arrange()
{
	stop();

	integer i;
	float delta = 2*PI/count;
	integer numPrims = getPrimCount();
	for(i=0; i<numPrims; i++)
	{
		vector direction;
		vector light = <radius, 0, 0>;
		if(randomRez)
		{
			rotation rot = llEuler2Rot(<llFrand(2*PI), llFrand(2*PI), llFrand(2*PI)>);
			direction = light * rot;
		}
		else
		{
			rotation rot = llEuler2Rot(<0, 0, i*delta>);
			direction = light * rot;
		}
		llSetLinkPrimitiveParamsFast(i+2, [PRIM_POSITION, direction]);
	}
}

clean()
{
	while(getPrimCount() > 1) llBreakLink(2);
}

getPermissions()
{
	if(!hasPermission) llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
}

integer getPrimCount()
{
	return llGetObjectPrimCount(llGetKey());
}

parseCommand(string message)
{
	list line = llParseString2List(message, [" "], []);
	integer length = llGetListLength(line);
	if(length == 0)return;
	string command = llToLower(llList2String(line, 0));

	if(command == "status") { showStatus(); return; }
	if(command == "authorize") { getPermissions(); return; }
	if(command == "arrange") { arrange(); return; }
	if(command == "clean") { clean(); return; }
	if(command == "start") { start(); return; }
	if(command == "stop") { stop(); return; }
	if(command == "count" && length == 2)
	{
		integer newCount= llList2Integer(line, 1);
		setCount(newCount);
		return;
	}
	if(command == "speed" && length == 2)
	{
		float newSpeed = llList2Float(line, 1);
		if(0 < newSpeed)
		{
			speed = newSpeed;
			say("Speed set to " + (string)speed);
		}
		else
		{
			say("Speed not set.");
		}
		return;
	}

	if(command == "radius" && length == 2)
	{
		integer newRadius = llList2Integer(line, 1);
		if(0 < newRadius && newRadius < 60)
		{
			radius = newRadius;
			say("Radius set to " + (string)radius);
		}
		else
		{
			say("Radius not set.");
		}
		return;
	}

	if(command == "style" && length == 2)
	{
		string subcommand = llToLower(llList2String(line, 1));
		randomRez = subcommand == "random";
		say("Style set.");
		return;
	}
}

rezOne(vector direction)
{
	string object=llGetInventoryName(INVENTORY_OBJECT,0);  //get name of the 1st object in inventory
	llRezObject(object, llGetPos() + direction, ZERO_VECTOR, ZERO_ROTATION, 0);  //rez the 1st object
	say("Created.");
	//<0.0, 0.0, 2>
}

say(string message)
{
	llSay(PUBLIC_CHANNEL, message);
}

setCount(integer newCount)
{
	stop();

	if(newCount < 0) newCount = 0;
	count = newCount;

	clean();

	if(newCount == 0) return;

	integer i;
	float delta = 2*PI/count;
	for(i=0; i<newCount; i++) rezOne(<0, 0, 2>);
}

showStatus()
{
	if(hasPermission) say("Has Permissions: Yes");
	else say("Has Permissions: No");
	say("Radius: " + (string)radius);
	say("Speed: " + (string)speed);
	say("Target count: " + (string)count);
	say("Prim count: " + (string)getPrimCount());
	if(randomRez) say("Style: Random");
	else say("Style: Regular");
}

start()
{
	//    llTargetOmega(<0, 0, 1>, 0.1, 1);
	float x = llFrand(2*PI);// - PI;
	float y = llFrand(2*PI);// - PI;
	float z = llFrand(2*PI);// - PI;
	llTargetOmega(llVecNorm(<x, y, z>), speed/100.0, 1);
	say("Starting.");
}

stop()
{
	llTargetOmega(ZERO_VECTOR, 0, 0);
	say("Stopping.");
}

default
{
	listen(integer channel, string name, key id, string message)
	{
		parseCommand(message);
	}
	object_rez(key id)
	{
		llCreateLink(id, TRUE);
		say("Linked.");
		if(getPrimCount() == count + 1) say("Rezzing completed.");
	}
	run_time_permissions(integer perm)
	{
		if (perm & PERMISSION_CHANGE_LINKS)
		{
			hasPermission = TRUE;
			say("Rez permissions acquired.");
		}
	}
	state_entry()
	{
		getPermissions();
		llListen(PUBLIC_CHANNEL, "", llGetOwner(), "");
	}
	touch_start(integer total_number)
	{
	}
}
