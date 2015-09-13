	if (isServer) then {
		[] spawn compilefinal preprocessFileLineNumbers "warcontext\init.sqf";
	};

	while { true } do {
		diag_log format ["fps: %1 groups: %2 ai: %3", diag_fps, count allGroups, (count allUnits + count alldead)];
		sleep 30;
	}