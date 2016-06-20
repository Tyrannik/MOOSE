
local FollowGroupSet = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("Follow Group"):FilterStart()
local LeaderUnit = UNIT:FindByName( "Leader" )
local LargeFormation = FOLLOW:New( LeaderUnit, FollowGroupSet, "Large Formation", "Briefing" )
