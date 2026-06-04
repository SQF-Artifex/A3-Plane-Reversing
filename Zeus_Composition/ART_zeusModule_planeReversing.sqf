

"Remote-Exec stuff for pub zeus";

0 = [] spawn {
    
	private _initREpack = [] spawn {
		comment "RE method 2, version 5";
		"REMOTE EXEC USAGE EXMAPLE:
            1. Define function you want to RE
            2. Init function with RE2 method
            3. Use RE2 funtion to run remotely
            1.
                M9_fnc_someSpicyCode = {
                    ...
                };
            2.
                ['M9_fnc_someSpicyCode', 'spawn'] call M9SD_fnc_REinit2_V5;
            3.
                [[], 'RE2_M9_fnc_someSpicyCodes', player] call M9SD_fnc_RE2_V5;
		";
		if (!isNil 'M9SD_fnc_RE2_V5') exitWith {};
		comment "Initialize Remote-Execution Package";
		M9SD_fnc_initRE2_V5 = {
			M9SD_fnc_initRE2Functions_V5 = {
				comment "Prep RE2 functions.";
				M9SD_fnc_REinit2_V5 = {
					params [['_functionName', ''], ['_schedule', 'call']];
					private _functionNameRE2 = '';
					"
                        if (isNil {
                            _functionNames
                        }) exitWith {
                            ''
                        };
					";
					if !(_functionName isEqualType '') exitWith {
						''
					};
					"
                        if (count _functionNames == 0) exitWith {
                            ''
                        };
					";
					'
                        private _functionNames = _this;
					';
					private _aString = "";
					private _namespaces = [missionNamespace, uiNamespace];
					{
						if !(_x isEqualType _aString) then {
							continue
						};
						private _functionName = _x;
						_functionNameRE2 = format ["RE2_%1", _functionName];
						{
							private _namespace = _x;
							with _namespace do {
								if (!isNil _functionName) then {
									private _fnc = _namespace getVariable [_functionName, {}];
									private _fncStr = str _fnc;
									private _fncStr2 = "{
										" +
										"removeMissionEventHandler ['EachFrame', _thisEventHandler];
										" +
										"(_thisArgs # 0) " + _schedule + " " + _fncStr +
										"
									}";
									private _fncStrArr = _fncStr2 splitString '';
									_fncStrArr deleteAt (count _fncStrArr - 1);
									_fncStrArr deleteAt 0;
									_namespace setVariable [_functionNameRE2, _fncStrArr, true];
								};
							};
						} forEach _namespaces;
					} forEach [_functionName];
					'
                        true;
					';
					_functionNameRE2;
				};
				M9SD_fnc_RE2_V5 = {
					params [["_REarguments", []], ["_REfncName2", ""], ["_REtarget", player], ["_JIPparam", false]];
					if (!((missionNamespace getVariable [_REfncName2, []]) isEqualType []) &&
					!((uiNamespace getVariable [_REfncName2, []]) isEqualType [])) exitWith {
						systemChat "::Error:: remoteExec failed (invalid _REfncName2 - not an array).";
					};
					if ((count (missionNamespace getVariable [_REfncName2, []]) == 0) &&
					(count (uiNamespace getVariable [_REfncName2, []]) == 0)) exitWith {
						systemChat "::Error:: remoteExec failed (invalid _REfncName2 - empty array).";
						systemChat str _REfncName2;
					};
					if (isNil _REfncName2) then {
						_REfncName2 = format ["RE2_%1", _REfncName2];
					};
					[[_REfncName2, _REarguments], {
						if (isNil (_this # 0)) exitWith {};
						addMissionEventHandler ["EachFrame", (missionNamespace getVariable [_this # 0, ['']]) joinString '', [_this # 1]];
					}] remoteExec ['call', _REtarget, _JIPparam];
				};
				comment "
                    systemChat '[ RE2 Package ] : RE2 functions initialized.';
				";
			};
			M9SD_fnc_initRE2FunctionsGlobal_V5 = {
				comment "Prep RE2 functions on all clients+jip.";
				private _fncStr = format ["{
					removeMissionEventHandler ['EachFrame', _thisEventHandler];
					_thisArgs call %1
				}", M9SD_fnc_initRE2Functions_V5];
				_fncStr = _fncStr splitString '';
				_fncStr deleteAt (count _fncStr - 1);
				_fncStr deleteAt 0;
				missionNamespace setVariable ["RE2_M9SD_fnc_initRE2Functions_V5", _fncStr, true];
				[["RE2_M9SD_fnc_initRE2Functions_V5", []], {
					addMissionEventHandler ["EachFrame", (missionNamespace getVariable ["RE2_M9SD_fnc_initRE2Functions_V5", ['']]) joinString '', _this # 1];
				}] remoteExec ['call', 0, 'RE2_M9SD_JIP_initRE2Functions_V5'];
				comment "
                    Delete from jip queue: remoteExec ['', 'RE2_M9SD_JIP_initRE2Functions_V5'];
				";
			};
			call M9SD_fnc_initRE2FunctionsGlobal_V5;
		};
		call M9SD_fnc_initRE2_V5;
		waitUntil {
			!isNil 'M9SD_fnc_RE2_V5'
		};
		if (true) exitWith {
			true
		};
		'so'; true;
	};
	waitUntil {
		scriptDone _initREpack
	};
    'RE Pack Initialized...';

    

};


"--------------------------------------------------------------------------------------------";
"--------------------------------------------------------------------------------------------";
"--------------------------------------------------------------------------------------------";


"Plane-reversing stuff";

ART_fnc_enablePlaneReversing = {
    if (!canSuspend) exitWith {hint "This script cannot be run from the editor. It is meant to be used as a module in the Zeus interface."};
    comment 'Wait for RE2 to be ready';
    if ((isNil 'M9SD_fnc_RE2_V5') or (isNil 'M9SD_fnc_REinit2_V5')) exitWith {hint "Remote Execution functions not ready. Please wait a moment and try again."};

    comment 'Set up RE function';
    if (isNil 'RE2_ART_fnc_initPlaneReversing') then {
        ART_fnc_initPlaneReversing = {
            comment "-----------------------------------------------";
            if (!hasInterface) exitWith {};
            waitUntil { !isNil { player } && { !isNull player } };
            waitUntil { !isNull (findDisplay 46) };
            comment "-----------------------------------------------";

            "Setup functions for plane reversing";


            ART_fnc_reversePlanePulse = {
                params [['_vehicle', objNull]];
                if (isNull _vehicle) exitWith {};
                if ((diag_tickTime - (missionNamespace getVariable ['ART_reversePlaneTimePrevious', 0])) < 0.01) exitWith {};
                "check for forward movement and brake if so";
                private _velocityArray = velocityModelSpace _vehicle;
                'systemChat str _velocityArray;';
                private _fwdVelocity = _velocityArray select 1;
                if (_fwdVelocity > 1) exitWith {};
                private _newFwdVelocity = -2;
                "
                if ((_fwdVelocity > -0.2) && (_fwdVelocity < 0.2)) then {
                    _newFwdVelocity = -0.3;
                } else {
                    if (_fwdVelocity < 0) then {
                        _newFwdVelocity = _fwdVelocity - 0.1;
                        if (_newFwdVelocity < -2) then {
                            _newFwdVelocity = -2;
                        };
                    };
                };
                ";
                if !(brakesDisabled _vehicle) then
                {
                    _vehicle disableBrakes true;
                };
                _vehicle addTorque (_vehicle vectorModelToWorld [((getmass _vehicle) / 4.875), 0, 0]);
                _vehicle setVelocityModelSpace [_velocityArray # 0, _newFwdVelocity, _velocityArray # 2];
                missionNamespace setVariable ['ART_reversePlaneTimePrevious', diag_tickTime];
            };

            ART_fnc_handleKB_planeReversing = {
                params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
                'if (_shift or _ctrl or _alt) exitWith {};';
                "Bind to car reverse (S)";
                if !((_key in (actionKeys "CarBack")) or (_key == 31)) exitWith {}; 
                if (isNull player) exitWith {};
                "Get vehicle object, accounting for possible remote-control by Zeus";
                private _vehicle = objNull;
                if (isRemoteControlling player) then {
                    _vehicle = cameraOn;
                } else {
                    if (isNull vehicle player) exitWith {};
                    if !(alive player && alive vehicle player) exitWith {}; 
                    if !(player in vehicle player) exitWith {};
                    if (player == vehicle player) exitWith {};
                    _vehicle = vehicle player;
                };
                "Check if vehicle is valid";
                if (isNull _vehicle) exitWith {};
                if (!(_vehicle isKindOf "Plane")) exitWith {};
                "Check if vehicle is on the ground and engine is on";
                if !(isEngineOn _vehicle) exitWith {};
                if !(isTouchingGround _vehicle) exitWith {};
                "control pulse frequency";
                [_vehicle] call ART_fnc_reversePlanePulse;
            };

            ART_fnc_removeKB_planeReversing = {
                if (isNull findDisplay 46) exitWith {};
                if (!isNil 'ART_kb_reversePlane') then 
                {
                    (findDisplay 46) displayRemoveEventHandler ['KeyDown', ART_kb_reversePlane];
                };
            };

            ART_fnc_addKB_initPlaneReversing = {
                if (isNull findDisplay 46) exitWith {};
                call ART_fnc_removeKB_planeReversing;
                ART_kb_reversePlane = (findDisplay 46) displayAddEventHandler ['KeyDown', ART_fnc_handleKB_planeReversing];
                if (!isNil 'ART_EH_planeReversingHint') then {
                    player removeEventHandler ["GetInMan", ART_EH_planeReversingHint];
                };
                ART_EH_planeReversingHint = player addEventHandler ["GetInMan", {
                    params ["_unit", "_role", "_vehicle", "_turret"];
                    if (missionnamespace getVariable ['ART_reversePlaneHintGiven', false]) exitWith {};
                    if (_vehicle isKindOf "Plane") then {
                        systemChat "TIP: Press “S” to reverse the plane (engine must be running).";
                    };
                    missionnamespace setVariable ['ART_reversePlaneHintGiven', true];
                }];
            };

            "Add keybind for plane reversing";

            call ART_fnc_addKB_initPlaneReversing;

        };

        ['ART_fnc_initPlaneReversing', 'spawn'] call M9SD_fnc_REinit2_V5;
    };

    comment 'Wait for function to be ready';
    waitUntil {!isNil 'RE2_ART_fnc_initPlaneReversing'}; 

    [[], 'RE2_ART_fnc_initPlaneReversing', 0, 'ART_JIP_initPlaneReversing'] call M9SD_fnc_RE2_V5; 

    "Notification";
    {playsound ['orange_periodswitch_notification', _x]} foreach [true, false];
    "planereversingmodulenotificationlayer" cutText [format ["<t shadow='0' font='PuristaBold' color='#ffffff' size='3'>Plane Reversing:<br/><br/><t color='#9dff90' shadow='0' font='Caveat'>Enabled!</t>"], "PLAIN", 0.25, true, true];

    "SERVER NOTIFICATION:  Zeus has ENABLED “Plane Reversing” for all players." remoteExec ['systemChat', 0];
    "Press “S” to reverse while in a plane." remoteExec ['systemChat', 0];
};

ART_fnc_disablePlaneReversing = {
    "remove init from jip queue";
    remoteExec ['', 'ART_JIP_initPlaneReversing'];
    
    if (!canSuspend) exitWith {hint "This script cannot be run from the editor. It is meant to be used as a module in the Zeus interface."};
    comment 'Wait for RE2 to be ready';
    if ((isNil 'M9SD_fnc_RE2_V5') or (isNil 'M9SD_fnc_REinit2_V5')) exitWith {hint "Remote Execution functions not ready. Please wait a moment and try again."};
    
    comment 'Set up RE function';
    if (isNil 'RE2_ART_fnc_uninitPlaneReversing') then {
        ART_fnc_uninitPlaneReversing = {
            comment "-----------------------------------------------";
            if (!hasInterface) exitWith {};
            waitUntil { !isNil { player } && { !isNull player } };
            waitUntil { !isNull (findDisplay 46) };
            comment "-----------------------------------------------";

            "Remove keybind for plane reversing";

            if (!isNil 'ART_kb_reversePlane') then 
            {
                (findDisplay 46) displayRemoveEventHandler ['KeyDown', ART_kb_reversePlane];
            };

            "Remove hint event handler for plane reversing";

            if (!isNil 'ART_EH_planeReversingHint') then {
                player removeEventHandler ["GetInMan", ART_EH_planeReversingHint];
            };

        };

        ['ART_fnc_uninitPlaneReversing', 'spawn'] call M9SD_fnc_REinit2_V5;

    };

    comment 'Wait for function to be ready';
    waitUntil {!isNil 'RE2_ART_fnc_uninitPlaneReversing'}; 

    [[], 'RE2_ART_fnc_uninitPlaneReversing', 0] call M9SD_fnc_RE2_V5; 

    "Notification";
    {playsound ['orange_periodswitch_notification', _x]} foreach [true, false];
    "planereversingmodulenotificationlayer" cutText [format ["<t shadow='0' font='PuristaBold' color='#ffffff' size='3'>Plane Reversing:<br/><br/><t color='#ff9090' shadow='0' font='Caveat'>Disabled!</t>"], "PLAIN", 0.25, true, true];

    "SERVER NOTIFICATION:  Zeus has DISABLED “Plane Reversing” for all players." remoteExec ['systemChat', 0];
};

ART_fnc_openPlaneReversingInitMenu = {
    with uiNamespace do {
        findDisplay 49 closeDisplay 0;
        private _txtSize = (safezoneh * 0.5) * 1.125;
        private _center = [0.5 * safezoneW + safezoneX,0.398611 * safezoneH + safezoneY,0.04125 * safezoneW,0.055 * safezoneH];
        private _fadeTime = 0.25;

        createDialog 'RscDisplayEmpty';
        private _display = findDisplay -1;

        private _ctrl_titlebar = _display ctrlCreate ['RscStructuredText', -1];
        _ctrl_titlebar ctrlEnable false;
        _ctrl_titlebar ctrlSetBackgroundColor [0.1,0.1,0.2,0.88];
        _ctrl_titlebar ctrlSetStructuredText parseText format ["<t align='center' shadow='0' color='#FFFFFF' size='%1'>CONTROL PANEL:  Plane Reversing</t>", _txtSize * 1.5];
        _ctrl_titlebar ctrlSetPosition _center;
        _ctrl_titlebar ctrlSetFade 1;
        _ctrl_titlebar ctrlCommit 0;
        _ctrl_titlebar ctrlSetFade 0;
        _ctrl_titlebar ctrlSetPosition [0.386561 * safezoneW + safezoneX,0.225 * safezoneH + safezoneY,0.226875 * safezoneW,0.033 * safezoneH];
        _ctrl_titlebar ctrlCommit _fadeTime;
        
        private _ctrl_bkgrnd = _display ctrlCreate ['RscStructuredText', -1];
        _display setVariable ['planeIconCtrl', _ctrl_bkgrnd];
        _ctrl_bkgrnd ctrlEnable false;
        _ctrl_bkgrnd ctrlSetBackgroundColor [0,0,0,0.77];
        _ctrl_bkgrnd ctrlSetStructuredText parseText format ["<t align='center' shadow='0' color='#FFFFFF' size='%1'><img image='a3\air_f_exp\plane_civil_01\data\ui\plane_civil_01_ca.paa'></img><img image='a3\ui_f\data\gui\rsccommon\rschtml\arrow_right_ca.paa'></img></t>", _txtSize * 5];
        _ctrl_bkgrnd ctrlSetPosition _center;
        _ctrl_bkgrnd ctrlSetFade 1;
        _ctrl_bkgrnd ctrlCommit 0;
        _ctrl_bkgrnd ctrlSetFade 0;
        _ctrl_bkgrnd ctrlSetPosition [0.386562 * safezoneW + safezoneX,0.269 * safezoneH + safezoneY,0.226875 * safezoneW,0.11 * safezoneH];
        _ctrl_bkgrnd ctrlCommit _fadeTime;


        private _ctrl_btn_enable = _display ctrlCreate ['RscButtonMenu', -1];
        _ctrl_btn_enable ctrlSetBackgroundColor [0,0.1,0,0.88];
        _ctrl_btn_enable ctrlSetStructuredText parseText format ["<t align='center' shadow='0' color='#FFFFFF' size='%1'>ENABLE</t>", _txtSize * 1.4];
        _ctrl_btn_enable ctrlSetTooltip "Enable the plane reversing controls for all current and future players (adds JIP).";
        _ctrl_btn_enable ctrlAddEventHandler ['ButtonClick', {
            params ["_control"];
            private _display = ctrlParent _control;
            '_display closeDisplay 0;';
            systemChat "Enabling plane reversing controls...";
            [] spawn ART_fnc_enablePlaneReversing;
            playsound 'bobcat_engine_start';

            _display spawn {
                private _display = _this;
                private _planeIconCtrl = _display getVariable 'planeIconCtrl';
                _planeIconCtrl ctrlSetBackgroundColor [0,0,0,0];
                _planeIconCtrl ctrlCommit 0;
                private _startTime = diag_tickTime;
                {
                    if (_x == _planeIconCtrl) then {continue};
                    _x ctrlEnable false;
                    _x ctrlSetFade 1;
                    _x ctrlCommit 0.25;
                } forEach allControls _display;
                while {!isNull _display} do {
                    if (diag_tickTime - _startTime > 2.25) then {
                        _planeIconCtrl ctrlSetFade 1;
                        _planeIconCtrl ctrlCommit 0.5;
                        _display spawn {uiSleep 0.5; _this closeDisplay 0;};
                    };
                    private _ctrlPos = ctrlPosition _planeIconCtrl;
                    _ctrlPos set [0, (_ctrlPos select 0) + 0.002];
                    _planeIconCtrl ctrlSetPosition _ctrlPos;
                    _planeIconCtrl ctrlCommit 0.01;
                    uiSleep 0.01;
                };
            };

        }];
        _ctrl_btn_enable ctrlSetPosition _center;
        _ctrl_btn_enable ctrlSetFade 1;
        _ctrl_btn_enable ctrlCommit 0;
        _ctrl_btn_enable ctrlSetFade 0;
        _ctrl_btn_enable ctrlSetPosition [0.386562 * safezoneW + safezoneX,0.39 * safezoneH + safezoneY,0.0825 * safezoneW,0.033 * safezoneH];
        _ctrl_btn_enable ctrlCommit _fadeTime;

        private _ctrl_btn_cancel = _display ctrlCreate ['RscButtonMenu', -1];
        _ctrl_btn_cancel ctrlSetBackgroundColor [0.1,0.1,0.1,0.88];
        _ctrl_btn_cancel ctrlSetStructuredText parseText format ["<t align='center' shadow='0' color='#FFFFFF' size='%1'>CANCEL</t>", _txtSize * 1.2];
        _ctrl_btn_cancel ctrlSetTooltip "Cancel the module and close this menu.";
        _ctrl_btn_cancel ctrlAddEventHandler ['ButtonClick', {
            params ["_control"];
            private _display = ctrlParent _control;
            _display closeDisplay 0;
            {playsound ['orange_lights_off', _x]} foreach [true, false]; 
        }];
        _ctrl_btn_cancel ctrlSetPosition _center;
        _ctrl_btn_cancel ctrlSetFade 1;
        _ctrl_btn_cancel ctrlCommit 0;
        _ctrl_btn_cancel ctrlSetFade 0;
        _ctrl_btn_cancel ctrlSetPosition [0.474219 * safezoneW + safezoneX,0.39 * safezoneH + safezoneY,0.0515625 * safezoneW,0.033 * safezoneH];
        _ctrl_btn_cancel ctrlCommit _fadeTime;

        private _ctrl_btn_disable = _display ctrlCreate ['RscButtonMenu', -1];
        _ctrl_btn_disable ctrlSetBackgroundColor [0.1,0,0,0.88];
        _ctrl_btn_disable ctrlSetStructuredText parseText format ["<t align='center' shadow='0' color='#FFFFFF' size='%1'>DISABLE</t>", _txtSize * 1.4];
        _ctrl_btn_disable ctrlSetTooltip "Disable the plane reversing controls for all players.\nRemoves the keybind from current and future players (removes JIP).";
        _ctrl_btn_disable ctrlAddEventHandler ['ButtonClick', {
            params ["_control"];
            private _display = ctrlParent _control;
            _display closeDisplay 0;
            systemChat "Disabling plane reversing controls...";
            [] spawn ART_fnc_disablePlaneReversing;
        }];
        _ctrl_btn_disable ctrlSetPosition _center;
        _ctrl_btn_disable ctrlSetFade 1;
        _ctrl_btn_disable ctrlCommit 0;
        _ctrl_btn_disable ctrlSetFade 0;
        _ctrl_btn_disable ctrlSetPosition [0.530937 * safezoneW + safezoneX,0.39 * safezoneH + safezoneY,0.0825 * safezoneW,0.033 * safezoneH];
        _ctrl_btn_disable ctrlCommit _fadeTime;
    };
};

ART_fnc_modulePlaneReversing = {
    comment "Determine if execution context is composition and delete the helipad.";
    if ((!isNull (findDisplay 312)) && (!isNil 'this')) then {
        if (!isNull this) then {
            if (typeOf this == 'Land_HelipadEmpty_F') then {
                deleteVehicle this;
            };
        };
    };
    0 = [] spawn ART_fnc_openPlaneReversingInitMenu;
};

call ART_fnc_modulePlaneReversing;

':)';