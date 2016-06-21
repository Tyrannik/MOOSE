
local FollowGroupSet = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("Follow Group"):FilterStart()
FollowGroupSet:Flush()
local LeaderUnit = UNIT:FindByName( "Leader" )
local LargeFormation = FOLLOW:New( LeaderUnit, FollowGroupSet, "Large Formation", "Briefing" )--:TestSmokeDirectionVector(true)
