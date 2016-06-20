--- This module contains the FOLLOW class.
-- 
-- 1) @{Follow#FOLLOW} class, extends @{Base#BASE}
-- ===============================================
-- The @{#FOLLOW} class allows you to build large formations, make AI follow a @{Client#CLIENT} (player) leader or a @{Unit#UNIT} (AI) leader.
--
--
-- 1.1) FOLLOW construction:
-- -------------------------
-- Create a new SPAWN object with the @{#FOLLOW.New} method:
--
--  * @{Follow#FOLLOW.New}(): Creates a new FOLLOW object from a @{Group#GROUP} for a @{Client#CLIENT} or a @{Unit#UNIT}, with an optional briefing text.
--
-- FOLLOW initialization methods.
-- ==============================
-- The following menus are created within the RADIO MENU of an active unit hosted by a player:
-- 
--  * @{Follow#FOLLOW.SetFormation}(): Set a Vec3 position for a GroupName within the GroupSet following.
--
-- @usage
-- -- Declare a new FollowPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local FollowUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local FollowGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Follow Client.
-- 
-- -- Now use these 2 objects to construct the new FollowPlanes object.
-- FollowPlanes = FOLLOW:New( FollowUnit, FollowGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
-- 
-- ===
--
-- @module Follow
-- @author FlightControl

--- FOLLOW class
-- @type FOLLOW
-- @extends Base#BASE
-- @field Unit#UNIT FollowUnit
-- @field Set#SET_GROUP FollowGroupSet
-- @field #string FollowName
-- @field #FOLLOW.MODE FollowMode The mode the escort is in.
-- @field Scheduler#SCHEDULER FollowScheduler The instance of the SCHEDULER class.
-- @field #number FollowDistance The current follow distance.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCSTypes#AI.Option.Air.val.ROE OptionROE Which ROE is set to the FollowGroup.
-- @field DCSTypes#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the FollowGroup.
-- @field Menu#MENU_CLIENT FollowMenuResumeMission
FOLLOW = {
  ClassName = "FOLLOW",
  FollowName = nil, -- The Follow Name
  FollowUnit = nil,
  FollowGroupSet = nil,
  FollowMode = 1,
  MODE = {
    FOLLOW = 1,
    MISSION = 2,
  },
  FollowScheduler = nil,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
}

--- FOLLOW.Mode class
-- @type FOLLOW.MODE
-- @field #number FOLLOW
-- @field #number MISSION

--- MENUPARAM type
-- @type MENUPARAM
-- @field #FOLLOW ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- FOLLOW class constructor for an AI group
-- @param #FOLLOW self
-- @param Unit#UNIT FollowUnit The UNIT leading the FolllowGroupSet.
-- @param Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string FollowName Name of the escort.
-- @return #FOLLOW self
function FOLLOW:New( FollowUnit, FollowGroupSet, FollowName, FollowBriefing )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( { FollowUnit, FollowGroupSet, FollowName } )

  self.FollowUnit = FollowUnit -- Unit#UNIT
  self.FollowGroupSet = FollowGroupSet -- Set#SET_GROUP
  
  self.FollowGroupSet:ForEachGroup(
    --- @param Group#GROUP FollowGroup
    function( FollowGroup, FollowName, FollowUnit )
      local Vec3 = { x = math.random( -20, -400 ), y = math.random( -100, 100 ), z = math.random( -200, 200 ) }
      FollowGroup:SetState( self, "Vec3", Vec3 )
      FollowGroup:OptionROTPassiveDefense()
      FollowGroup:OptionROEReturnFire()
      FollowGroup:MessageToClient( FollowGroup:GetCategoryName() .. " '" .. FollowName .. "' (" .. FollowGroup:GetCallsign() .. ") reporting! " ..
        "We're following your flight. ",
        60, FollowUnit
      )
    end,
    FollowName, self.FollowUnit
  )

  
  self.FollowName = FollowName
  self.FollowBriefing = FollowBriefing


  self.CT1 = 0
  self.GT1 = 0
  self.FollowScheduler = SCHEDULER:New( self, self._FollowScheduler, {}, 1, .5, .01 )
  self.FollowMode = FOLLOW.MODE.MISSION

  return self
end

--- This function is for test, it will put on the frequency of the FollowScheduler a red smoke at the direction vector calculated for the escort to fly to.
-- This allows to visualize where the escort is flying to.
-- @param #FOLLOW self
-- @param #boolean SmokeDirection If true, then the direction vector will be smoked.
function FOLLOW:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
end


--- @param Follow#FOLLOW self
function FOLLOW:_FollowScheduler()
  self:F( )

  self:T( { self.FollowUnit.UnitName }, self.FollowUnit:IsAlive() )
  if self.FollowUnit:IsAlive() then

    local ClientUnit = self.FollowUnit
    
    self.FollowGroupSet:ForEachGroup(
      --- @param Group#GROUP FollowGroup
      function( FollowGroup, ClientUnit )
        local GroupUnit = self.FollowGroup:GetUnit( 1 )
        local FollowFormation = FollowGroup:GetState( self, "Vec3" )
        local FollowDistance = -FollowFormation.x
        
        self:T( {ClientUnit.UnitName, GroupUnit.UnitName } )
    
        if self.CT1 == 0 and self.GT1 == 0 then
          self.CV1 = ClientUnit:GetPointVec3()
          self:T( { "self.CV1", self.CV1 } )
          self.CT1 = timer.getTime()
          self.GV1 = GroupUnit:GetPointVec3()
          self.GT1 = timer.getTime()
        else
          local CT1 = self.CT1
          local CT2 = timer.getTime()
          local CV1 = self.CV1
          local CV2 = ClientUnit:GetPointVec3()
          self.CT1 = CT2
          self.CV1 = CV2
    
          local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
          local CT = CT2 - CT1
    
          local CS = ( 3600 / CT ) * ( CD / 1000 )
    
          self:T2( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )
    
          local GT1 = self.GT1
          local GT2 = timer.getTime()
          local GV1 = self.GV1
          local GV2 = GroupUnit:GetPointVec3()
          self.GT1 = GT2
          self.GV1 = GV2
    
          local GD = ( ( GV2.x - GV1.x )^2 + ( GV2.y - GV1.y )^2 + ( GV2.z - GV1.z )^2 ) ^ 0.5
          local GT = GT2 - GT1
    
          local GS = ( 3600 / GT ) * ( GD / 1000 )
    
          self:T2( { "Group:", GS, GD, GT, GV2, GV1, GT2, GT1 } )
    
          -- Calculate the group direction vector
          local GV = { x = GV2.x - CV2.x, y = GV2.y - CV2.y, z = GV2.z - CV2.z }
    
          -- Calculate GH2, GH2 with the same height as CV2.
          local GH2 = { x = GV2.x, y = CV2.y, z = GV2.z }
    
          -- Calculate the angle of GV to the orthonormal plane
          local alpha = math.atan2( GV.z, GV.x )
    
          -- Now we calculate the intersecting vector between the circle around CV2 with radius FollowDistance and GH2.
          -- From the GeoGebra model: CVI = (x(CV2) + FollowDistance cos(alpha), y(GH2) + FollowDistance sin(alpha), z(CV2))
          local CVI = { x = CV2.x + FollowDistance * math.cos(alpha),
            y = GH2.y,
            z = CV2.z + FollowDistance * math.sin(alpha),
          }
    
          -- Calculate the direction vector DV of the escort group. We use CVI as the base and CV2 as the direction.
          local DV = { x = CV2.x - CVI.x, y = CV2.y - CVI.y, z = CV2.z - CVI.z }
    
          -- We now calculate the unary direction vector DVu, so that we can multiply DVu with the speed, which is expressed in meters / s.
          -- We need to calculate this vector to predict the point the escort group needs to fly to according its speed.
          -- The distance of the destination point should be far enough not to have the aircraft starting to swipe left to right...
          local DVu = { x = DV.x / FollowDistance, y = DV.y / FollowDistance, z = DV.z / FollowDistance }
    
          -- Now we can calculate the group destination vector GDV.
          local GDV = { x = DVu.x * CS * 8 + CVI.x, y = CVI.y, z = DVu.z * CS * 8 + CVI.z }
          
          local GDV_Formation = { x = GDV.x + FollowFormation.x, y = GDV.y + FollowFormation.y, z = GDV.z + FollowFormation.z }
          
          if self.SmokeDirectionVector == true then
            trigger.action.smoke( GDV, trigger.smokeColor.Red )
            trigger.action.smoke( GDV_Formation, trigger.smokeColor.Red )
          end
          
          self:T2( { "CV2:", CV2 } )
          self:T2( { "CVI:", CVI } )
          self:T2( { "GDV:", GDV } )
    
          -- Measure distance between client and group
          local CatchUpDistance = ( ( GDV_Formation.x - GV2.x )^2 + ( GDV_Formation.y - GV2.y )^2 + ( GDV_Formation.z - GV2.z )^2 ) ^ 0.5
    
          -- The calculation of the Speed would simulate that the group would take 30 seconds to overcome
          -- the requested Distance).
          local Time = 10
          local CatchUpSpeed = ( CatchUpDistance - ( CS * 8.4 ) ) / Time
    
          local Speed = CS + CatchUpSpeed
          if Speed < 0 then
            Speed = 0
          end
    
          self:T( { "Client Speed, Follow Speed, Speed, FollowDistance, Time:", CS, GS, Speed, FollowDistance, Time } )
    
          -- Now route the escort to the desired point with the desired speed.
          self.FollowGroup:TaskRouteToVec3( GDV_Formation, Speed / 3.6 ) -- DCS models speed in Mps (Miles per second)
        end
      end,
      ClientUnit
    )

    return true
  end

  return false
end

