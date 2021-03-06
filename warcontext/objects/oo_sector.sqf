﻿	/*
	Author: code34 nicolas_boiteux@yahoo.fr
	Copyright (C) 2014-2015 Nicolas BOITEUX

	CLASS OO_SECTOR STRATEGIC GRID
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>. 
	*/

	#include "oop.h"

	CLASS("OO_SECTOR")
		PRIVATE STATIC_VARIABLE("scalar","index");
		PRIVATE VARIABLE("bool","alert");
		PRIVATE VARIABLE("code","grid");	
		PRIVATE VARIABLE("string","marker");
		PRIVATE VARIABLE("array","sector");
		PRIVATE VARIABLE("scalar","state");
		PRIVATE VARIABLE("array","position");
		PRIVATE VARIABLE("scalar","grpnumber");
		PRIVATE VARIABLE("array","units");
		PRIVATE VARIABLE("scalar","bucket");

		PUBLIC FUNCTION("array","constructor") {
			private["_air", "_index", "_sniper", "_type", "_vehicle"];

			_index = MEMBER("index",nil);
			if (isNil "_index") then {_index = 0;};
			_index = _index + 1;
			MEMBER("index",_index);

			MEMBER("sector", _this select 0);
			MEMBER("position", _this select 1);
			MEMBER("grid", _this select 2);

			MEMBER("bucket", 0);
			MEMBER("state", 0);
			MEMBER("alert", false);

			_number = 1 + random 5;
			MEMBER("grpnumber", _number);			
			//MEMBER("setMission", nil);
		};

		PUBLIC FUNCTION("","getIndex") FUNC_GETVAR("index");
		PUBLIC FUNCTION("","getSector") FUNC_GETVAR("sector");
		PUBLIC FUNCTION("","getMarker") FUNC_GETVAR("marker");
		PUBLIC FUNCTION("","getAlert") FUNC_GETVAR("alert");
		PUBLIC FUNCTION("","getPosition") FUNC_GETVAR("position");
		PUBLIC FUNCTION("","getState") FUNC_GETVAR("state");

		PUBLIC FUNCTION("", "getThis") {
			private ["_key", "_sector"];
			_key = MEMBER("sector", nil);
			_sector = ["get", str(_key)] call global_zone_hashmap;
			_sector;
		};

		// 0 - unactivate
		// 1 - activate
		// 2 - done
		PRIVATE FUNCTION("scalar", "setState") {
			MEMBER("state", _this);
		};

		PUBLIC FUNCTION("", "setMission") {
			private ["_position"];
			_position = MEMBER("getPosition", nil);
			_mission = ["new", [_position]] spawn OO_MISSION;
		};

		PUBLIC FUNCTION("", "draw") {
			private ["_marker"];
			_marker = createMarker [format["mrk%1", MEMBER("index", nil)], MEMBER("position", nil)];
			_marker setMarkerShape "RECTANGLE";
			_marker setmarkerbrush "Solid";
			_marker setmarkercolor "ColorRed";
			_marker setmarkersize [50,50];
			MEMBER("marker", _marker);
		};

		PUBLIC FUNCTION("", "unDraw") {
			deletemarker MEMBER("marker", nil);
		};

		PUBLIC FUNCTION("", "popSector") {
			private ["_marker", "_object", "_units", "_grpnumber", "_type"];

			_grpnumber = MEMBER("grpnumber", nil);
			_units = [];
			_object = MEMBER("getThis", nil);

			MEMBER("alert", true);

			for "_i" from 1 to _grpnumber step 1 do {
				_units = _units + MEMBER("popInfantry", nil);
				sleep 0.01;
			};

			MEMBER("units", _units);
		};

		PUBLIC FUNCTION("", "unPopSector") {
			private ["_group", "_units"];
			_group = [];

			{
				if!(group _x in _group) then {
					_group = _group + [group _x];
				};
				_x removeEventHandler ["killed", 0];
				_x setdammage 1;
				deletevehicle _x;
				sleep 0.01;
			}foreach MEMBER("units", nil);

			{
				deleteGroup _x;
				sleep 0.01;
			}foreach _group;

			_units = [];
			MEMBER("units", _units);
		};

		PUBLIC FUNCTION("", "occupedSector") {
			private ["_sector", "_sectors"];
			_sectors = [];
			{
				_sector = ["getSectorFromPos", position _x] call _grid;
				if!(_sector in _sectors) then {
					_sectors = _sectors + [_sector];
				};
				sleep 0.0001;
			}foreach MEMBER("units", nil);
			_sectors = _sectors + [MEMBER("sector", nil)];
			_sectors;
		};

		PUBLIC FUNCTION("", "spawn") {
			private ["_deadcounter", "_array", "_around", "_bucket", "_mincost", "_cost", "_cost2", "_run", "_grid", "_player_sector", "_sector", "_units", "_position", "_vehicle", "_type", "_sectors", "_sector", "_popsquaredistance"];

			MEMBER("state", 1);
			MEMBER("marker", nil) setmarkercolor "ColorOrange";
			MEMBER("popSector", nil);

			_grid = MEMBER("grid", nil);
			_sector = MEMBER("sector", nil);
			_position = MEMBER("position", nil);

			_time = 0;
			_deadcounter = 0;
			_popsquaredistance = wcpopsquaredistance + 1;

			_run = true;
			while { _run } do {
				_run = false;
				_units = 0;
				_mincost = 100;
				_bucket = 0;

				_sectors = MEMBER("occupedSector", nil);
				{
					_player_sector = ["getSectorFromPos", position _x] call _grid;
					{
						_cost = ["GetEstimateCost", [_player_sector, _x]] call _grid;
						if(_cost < _mincost) then { _mincost = _cost;};
						sleep 0.0001;
					}foreach _sectors;
					_cost2 = ["GetEstimateCost", [_player_sector, _sector]] call _grid;
					if(_cost2 < _popsquaredistance) then {_bucket = _bucket + 1;};
					sleep 0.0001;
				}foreach playableunits;
				if(MEMBER("bucket", nil) < _bucket) then { MEMBER("bucket", _bucket);};

				if(MEMBER("alert", nil) and (_mincost < _popsquaredistance)) then {
					MEMBER("marker", nil) setmarkercolor "ColorYellow";
					_run = true;
				} else {
					if(_mincost < _popsquaredistance) then {
						MEMBER("marker", nil) setmarkercolor "ColorOrange";
						_run = true;
					};
				};

				{
					if((alive _x) and (_position distance _x < 2000)) then { _units = _units + 1;};
					sleep 0.01
				}foreach MEMBER("units", nil);
				if(_units == 0) then { _run = false; };
				if(_units < 3)then { _deadcounter = _deadcounter + 1;};
				if(_deadcounter > 500) then { _units = 0; _run = false;};
				sleep 1;
			};

			if(_units == 0) then {
				MEMBER("setVictory", nil);
			} else {
				MEMBER("UnSpawn", nil);
			};
		};

		PUBLIC FUNCTION("", "setVictory") {
			private ["_position", "_sector"];
			MEMBER("marker", nil) setmarkercolor "ColorBlue";
			MEMBER("state", 2);
			["setTicket", "bluezone"] call global_ticket;
			_position = MEMBER("getPosition", nil);

			wcsectorcompleted = MEMBER("getSector", nil);
			["wcsectorcompleted", "client"] call BME_fnc_publicvariable;

			_position = [_position, 0,50,5,0,3,0] call BIS_fnc_findSafePos;
			["new", _position] spawn OO_BONUSVEHICLE;
			MEMBER("unPopSector", nil);
			sleep 120;
			["deleteSector", MEMBER("getSector", nil)] call global_controller;
		};

		PUBLIC FUNCTION("bool", "setAlert") {
			MEMBER("alert", _this);
		};

		PUBLIC FUNCTION("bool", "setAlertAround") {
			MEMBER("alert", _this);
			["expandAlertAround", MEMBER("getSector", nil)] call global_controller;
		};

		PUBLIC FUNCTION("", "UnSpawn") {
			private ["_critical"];
			MEMBER("marker", nil) setmarkercolor "ColorRed";
			MEMBER("unPopSector", nil);
			if(MEMBER("getAlert", nil)) then { 
				if(random 1> 0.97) then {
					_critical = MEMBER("bucket", nil) * 2;
				} else {
					_critical = MEMBER("bucket", nil);
				};
				["expandSectorAround", [MEMBER("getSector", nil), _critical]] call global_controller;
			};
			//MEMBER("setAlert", false);
			MEMBER("state", 0);
			MEMBER("bucket", 0);
		};

		PRIVATE FUNCTION("", "popInfantry") {
			private ["_handle","_marker","_markersize","_markerpos","_type","_sector","_position","_group", "_position2"];

			_marker	=  MEMBER("marker", nil);		
			_markerpos 	= getmarkerpos _marker;
			_markersize	= (getMarkerSize _marker) select 1;
		
			_type = wcinfantrysquads call BIS_fnc_selectRandom;
		
			_position = [_markerpos, 0,50,1,0,3,0] call BIS_fnc_findSafePos;
			_position2 = getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition");
			if(_position isequalto _position2)  exitwith {[];};
		
			_group = [_position, east, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "infantry" >> _type)] call BIS_fnc_spawnGroup;
		
			{
				_handle = [_x, _type] spawn WC_fnc_setskill;
				_zombie = ["new", _x] call OO_INFECTED;
				"monitor" spawn _zombie;
				sleep 0.1;
			}foreach (units _group);	

			units _group;
		};


		PUBLIC FUNCTION("","deconstructor") { 
			DELETE_VARIABLE("alert");
			DELETE_VARIABLE("bucket");
			DELETE_VARIABLE("grid");
			DELETE_VARIABLE("index");
			deletemarker MEMBER("marker", nil);
			DELETE_VARIABLE("marker");
			DELETE_VARIABLE("sector");
			DELETE_VARIABLE("position");
			DELETE_VARIABLE("units");
			DELETE_VARIABLE("grpnumber");
			DELETE_VARIABLE("state");
		};
	ENDCLASS;