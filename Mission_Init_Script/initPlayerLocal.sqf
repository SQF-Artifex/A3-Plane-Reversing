
"Plane-reversing stuff (mission script: initPlayerLocal.sqf version)";

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

[] spawn ART_fnc_initPlaneReversing;

':)';