#include "BIS_AddonInfo.hpp"
class CfgPatches
{
	class ART_planeReversing
	{
		units[]={};
		weapons[]={};
		requiredAddons[]=
		{
			"A3_Data_F",
			"A3_UI_F"
		};
		requiredVersion=0.1;
		author[]=
		{
			"M9-SD"
		};
		authorUrl="https://steamcommunity.com/id/SQF_Artifex/myworkshopfiles/?appid=107410";
		version="1.00";
		versionAr[]={1,00};
		versionStr="1.00";
		mail="";
		fileName="ART_planeReversing.pbo";
	};
};
class CfgFunctions
{
	class ART_planeReversing
	{
		class ART_planeReversing
		{
			class postInit
			{
				file="\ART_planeReversing\Functions\ART_fnc_initPlaneReversingMod.sqf";
				postInit=1;
			};
		};
	};
};