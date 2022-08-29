function retVal2 = getMovementText(moveType)
retVal2 = char(zeros([1 50]));
switch moveType
    case uint16(movementTypes.FIST)
        retVal = 'Prepare: Squeeze Fist';
    case uint16(movementTypes.THUMB)
        retVal = 'Prepare: Thumb';
    case uint16(movementTypes.INDEX)
        retVal = 'Prepare: Index Finger';
    case uint16(movementTypes.MIDDLE)
        retVal = 'Prepare: Middle Finger';
    case uint16(movementTypes.RING)
        retVal = 'Prepare: Ring Finger';
    case uint16(movementTypes.WRISTFLEX)
        retVal = 'Prepare: Wrist Flexion';
    case uint16(movementTypes.WRISTROT)
        retVal = 'Prepare: Wrist Rotation';
    case uint16(movementTypes.ELBOWFLEX)
        retVal = 'Prepare: Bicep Flex'; % SDS Sep 2016 changed to "Bicep Flex" from just "Elbow"
    case uint16(movementTypes.HUMERALIN)
        retVal = 'Prepare: Forearm In';
    case uint16(movementTypes.ULNAR)
        retVal = 'Prepare: Ulnar Deviation';
    case uint16(movementTypes.SHOULDFLEX)
        retVal = 'Prepare: Shoulder Flexion';
    case uint16(movementTypes.SHOULDABDUCT)
        retVal = 'Prepare: Shoulder Abduction';

    
    
    
    case uint16(movementTypes.TORSO_TWIST)
        retVal = 'Prepare: Torso Twist';
    case uint16(movementTypes.BOW)
        retVal = 'Prepare: Bow';
    case uint16(movementTypes.LEG_RAISE)
        retVal = 'Prepare: Leg Raise';
    case uint16(movementTypes.KICK)
        retVal = 'Prepare: Kick';
    case uint16(movementTypes.FOOT_DOWN)
        retVal = 'Prepare: Foot Down';
    case uint16(movementTypes.NOD_HEAD)
        retVal = 'Prepare: Nod Head';
    case uint16(movementTypes.SHAKE_HEAD)
        retVal = 'Prepare: Shake Head';
    case uint16(movementTypes.SAY_BA)
        retVal = 'Prepare: Say Ba';
    case uint16(movementTypes.SAY_GA)
        retVal = 'Prepare: Say Ga';
    
    case uint16(movementTypes.WRIST_ULNAR_DEVIATE)
        retVal = 'Prepare: Wrist Down';   
    case uint16(movementTypes.WRIST_RADIAL_DEVIATE)
        retVal = 'Prepare: Wrist Up';
    case uint16(movementTypes.WRIST_PRONATE)
        retVal = 'Prepare: Wrist CCW';
    case uint16(movementTypes.WRIST_SUPINATE)
        retVal = 'Prepare: Wrist Clockwise'; 
        
    case uint16(movementTypes.SHOULDER_INTERNAL_ROT)
        retVal = 'Prepare: Shoulder Left';
    case uint16(movementTypes.SHOULDER_EXTERNAL_ROT)
        retVal = 'Prepare: Shoulder Right';
        
    case uint16(movementTypes.CONTRA_FIST)
        retVal = 'Prepare: Left Fist';
    case uint16(movementTypes.PURSE_LIPS)
        retVal = 'Prepare: Purse Lips';
        
    case uint16(movementTypes.TURN_HEAD_RIGHT)
        retVal = 'Prepare: Turn Head Right';
    case uint16(movementTypes.TURN_HEAD_LEFT)
        retVal = 'Prepare: Turn Head Left';
    case uint16(movementTypes.TURN_HEAD_UP)
        retVal = 'Prepare: Turn Head Up';
    case uint16(movementTypes.TURN_HEAD_DOWN)
        retVal = 'Prepare: Turn Head Down';
        
    case uint16(movementTypes.HEAD_TILT_RIGHT)
        retVal = 'Prepare: Tilt Head Right';
    case uint16(movementTypes.HEAD_TILT_LEFT)
        retVal = 'Prepare: Tilt Head Left';
    case uint16(movementTypes.HEAD_FORWARD)
        retVal = 'Prepare: Push Head Forward';
    case uint16(movementTypes.HEAD_BACKWARD)
        retVal = 'Prepare: Pull Head Backward';
        
    case uint16(movementTypes.TONGUE_UP)
        retVal = 'Prepare: Tongue Up';
    case uint16(movementTypes.TONGUE_DOWN)
        retVal = 'Prepare: Tongue Down';
    case uint16(movementTypes.TONGUE_LEFT)
        retVal = 'Prepare: Tongue Left';
    case uint16(movementTypes.TONGUE_RIGHT)
        retVal = 'Prepare: Tongue Right';
        
    case uint16(movementTypes.EYES_UP)
        retVal = 'Prepare: Look Up';
    case uint16(movementTypes.EYES_DOWN)
        retVal = 'Prepare: Look Down';
    case uint16(movementTypes.EYES_LEFT)
        retVal = 'Prepare: Look Left';
    case uint16(movementTypes.EYES_RIGHT)
        retVal = 'Prepare: Look Right';
    
    case uint16(movementTypes.MOUTH_OPEN)
        retVal = 'Prepare: Open Mouth';
    case uint16(movementTypes.JAW_CLENCH)
        retVal = 'Prepare: Clench Jaw';
    case uint16(movementTypes.PUCKER_LIPS)
        retVal = 'Prepare: Pucker Lips';
    case uint16(movementTypes.RAISE_EYEBROWS)
        retVal = 'Prepare: Raise Eyebrows';
    case uint16(movementTypes.NOSE_WRINKLE)
        retVal = 'Prepare: Wrinkle Nose';
        
    case uint16(movementTypes.SHO_SHRUG)
        retVal = 'Prepare: Shrug Shoulder';
    case uint16(movementTypes.ARM_RAISE)
        retVal = 'Prepare: Raise Arm';
    case uint16(movementTypes.ARM_LOWER)
        retVal = 'Prepare: Lower Arm';
    case uint16(movementTypes.ELBOW_FLEX)
        retVal = 'Prepare: Flex Elbow In';
    case uint16(movementTypes.ELBOW_EXT)
        retVal = 'Prepare: Elbow Out';
    case uint16(movementTypes.WRIST_EXT)
        retVal = 'Prepare: Wrist Up';
    case uint16(movementTypes.WRIST_FLEX)
        retVal = 'Prepare: Wrist Down';
    case uint16(movementTypes.CLOSE_HAND)
        retVal = 'Prepare: Close Hand';
    case uint16(movementTypes.OPEN_HAND)
        retVal = 'Prepare: Open Hand';
        
    case uint16(movementTypes.THUMB_JOY_FORWARD)
        retVal = 'Prepare: Rollerball Forward';
    case uint16(movementTypes.THUMB_JOY_BACK)
        retVal = 'Prepare: Rollerbal Back';
    case uint16(movementTypes.THUMB_JOY_RIGHT)
        retVal = 'Prepare: Rollerball Right';
    case uint16(movementTypes.THUMB_JOY_LEFT)
        retVal = 'Prepare: Rollerball Left';
        
    case uint16(movementTypes.ANKLE_UP)
        retVal = 'Prepare: Gas Pedal Up';
    case uint16(movementTypes.ANKLE_DOWN)
        retVal = 'Prepare: Gas Pedal Down';
    case uint16(movementTypes.KNEE_EXTEND)
        retVal = 'Prepare: Extend Knee';
    case uint16(movementTypes.KNEE_FLEX)
        retVal = 'Prepare: Knee In';
    case uint16(movementTypes.LEG_UP)
        retVal = 'Prepare: Thigh Up';
    case uint16(movementTypes.LEG_DOWN)
        retVal = 'Prepare: Leg Down';
     case uint16(movementTypes.TOE_CURL)
        retVal = 'Prepare: Curl Toes';
    case uint16(movementTypes.TOE_OPEN)
        retVal = 'Prepare: Spread Toes';
        
    case uint16(movementTypes.TORSO_UP)
        retVal = 'Prepare: Torso Up';
    case uint16(movementTypes.TORSO_DOWN)
        retVal = 'Prepare: Bow';
    case uint16(movementTypes.TORSO_TWIST_RIGHT)
        retVal = 'Prepare: Twist Right';
    case uint16(movementTypes.TORSO_TWIST_LEFT)
        retVal = 'Prepare: Twist Left';
        
    case uint16(movementTypes.INDEX_RAISE)
        retVal = 'Prepare: Raise Index';
    case uint16(movementTypes.THUMB_UP)
        retVal = 'Prepare: Thumb Up';
          
    case uint16(movementTypes.LEFT_SHO_SHRUG)
        retVal = 'Prepare: Left Shoulder Shrug';
    case uint16(movementTypes.LEFT_ARM_RAISE)
        retVal = 'Prepare: Left Arm Raise';
    case uint16(movementTypes.LEFT_ARM_LOWER)
        retVal = 'Prepare: Left Arm Lower';
    case uint16(movementTypes.LEFT_ELBOW_FLEX)
        retVal = 'Prepare: Left Elbow Flex';
    case uint16(movementTypes.LEFT_ELBOW_EXT)
        retVal = 'Prepare: Left Elbow Extend';
    case uint16(movementTypes.LEFT_WRIST_EXT)
        retVal = 'Prepare: Left Wrist Up';
    case uint16(movementTypes.LEFT_WRIST_FLEX)
        retVal = 'Prepare: Left Wrist Down';
    case uint16(movementTypes.LEFT_CLOSE_HAND)
        retVal = 'Prepare: Left Close Hand';
    case uint16(movementTypes.LEFT_OPEN_HAND)
        retVal = 'Prepare: Left Open Hand';
        
    case uint16(movementTypes.RIGHT_SHO_SHRUG)
        retVal = 'Prepare: Right Shoulder Shrug';
    case uint16(movementTypes.RIGHT_ARM_RAISE)
        retVal = 'Prepare: Right Arm Raise';
    case uint16(movementTypes.RIGHT_ARM_LOWER)
        retVal = 'Prepare: Right Arm Lower';
    case uint16(movementTypes.RIGHT_ELBOW_FLEX)
        retVal = 'Prepare: Right Elbow Flex';
    case uint16(movementTypes.RIGHT_ELBOW_EXT)
        retVal = 'Prepare: Right Elbow Extend';
    case uint16(movementTypes.RIGHT_WRIST_EXT)
        retVal = 'Prepare: Right Wrist Up';
    case uint16(movementTypes.RIGHT_WRIST_FLEX)
        retVal = 'Prepare: Right Wrist Down';
    case uint16(movementTypes.RIGHT_CLOSE_HAND)
        retVal = 'Prepare: Right Close Hand';
    case uint16(movementTypes.RIGHT_OPEN_HAND)
        retVal = 'Prepare: Right Open Hand';
        
    case uint16(movementTypes.LEFT_ANKLE_UP)
        retVal = 'Prepare: Left Ankle Up';
    case uint16(movementTypes.LEFT_ANKLE_DOWN)
        retVal = 'Prepare: Left Ankle Down';
    case uint16(movementTypes.LEFT_KNEE_EXTEND)
        retVal = 'Prepare: Left Knee Extend';
    case uint16(movementTypes.LEFT_KNEE_FLEX)
        retVal = 'Prepare: Left Knee In';
    case uint16(movementTypes.LEFT_LEG_UP)
        retVal = 'Prepare: Left Knee Up';
    case uint16(movementTypes.LEFT_LEG_DOWN)
        retVal = 'Prepare: Left Leg Down';
    case uint16(movementTypes.LEFT_TOE_CURL)
        retVal = 'Prepare: Left Toes Curl';
    case uint16(movementTypes.LEFT_TOE_OPEN)
        retVal = 'Prepare: Left Toes Open';
        
    case uint16(movementTypes.RIGHT_ANKLE_UP)
        retVal = 'Prepare: Right Ankle Up';
    case uint16(movementTypes.RIGHT_ANKLE_DOWN)
        retVal = 'Prepare: Right Ankle Down';
    case uint16(movementTypes.RIGHT_KNEE_EXTEND)
        retVal = 'Prepare: Right Knee Extend';
    case uint16(movementTypes.RIGHT_KNEE_FLEX)
        retVal = 'Prepare: Right Knee In';
    case uint16(movementTypes.RIGHT_LEG_UP)
        retVal = 'Prepare: Right Knee Up';
    case uint16(movementTypes.RIGHT_LEG_DOWN)
        retVal = 'Prepare: Right Leg Down';
    case uint16(movementTypes.RIGHT_TOE_CURL)
        retVal = 'Prepare: Right Toes Curl';
    case uint16(movementTypes.RIGHT_TOE_OPEN)
        retVal = 'Prepare: Right Toes Open';

    case uint16(movementTypes.BREATHE_IN)
        retVal = 'Prepare: Breathe in';
    case uint16(movementTypes.BREATHE_OUT)
        retVal = 'Prepare: Breathe out';  
        
    case uint16(movementTypes.RIGHT_ARM_UP)
        retVal = 'Prepare: Right Arm Up';
    case uint16(movementTypes.RIGHT_ARM_DOWN)
        retVal = 'Prepare: Right Arm Down';  
    case uint16(movementTypes.RIGHT_ARM_RIGHT)
        retVal = 'Prepare: Right Arm Right';
    case uint16(movementTypes.RIGHT_ARM_LEFT)
        retVal = 'Prepare: Right Arm Left';  
    case uint16(movementTypes.RIGHT_ARM_IN)
        retVal = 'Prepare: Right Arm In';
    case uint16(movementTypes.RIGHT_ARM_OUT)
        retVal = 'Prepare: Right Arm Out';  
        
    case uint16(movementTypes.LEFT_ARM_UP)
        retVal = 'Prepare: Left Arm Up';
    case uint16(movementTypes.LEFT_ARM_DOWN)
        retVal = 'Prepare: Left Arm Down';  
    case uint16(movementTypes.LEFT_ARM_RIGHT)
        retVal = 'Prepare: Left Arm Right';
    case uint16(movementTypes.LEFT_ARM_LEFT)
        retVal = 'Prepare: Left Arm Left';  
    case uint16(movementTypes.LEFT_ARM_IN)
        retVal = 'Prepare: Left Arm In';
    case uint16(movementTypes.LEFT_ARM_OUT)
        retVal = 'Prepare: Left Arm Out';  
        
    case uint16(movementTypes.CABLE_UP)
        retVal = 'Prepare: Cable Up';
    case uint16(movementTypes.CABLE_DOWN)
        retVal = 'Prepare: Cable Down';  
    case uint16(movementTypes.CABLE_RIGHT)
        retVal = 'Prepare: Cable Right';
    case uint16(movementTypes.CABLE_LEFT)
        retVal = 'Prepare: Cable Left';  

    case uint16(movementTypes.IMAGINE_BIRDS)
        retVal = 'Prepare: Imagine Birds';
    case uint16(movementTypes.IMAGINE_OUTER_SPACE)
        retVal = 'Prepare: Imagine Outer Space';  
    case uint16(movementTypes.IMAGINE_DESERT)
        retVal = 'Prepare: Imagine the Desert';
    case uint16(movementTypes.IMAGINE_HIGHWAY)
        retVal = 'Prepare: Imagine a Highway';  
    case uint16(movementTypes.IMAGINE_ELEPHANT)
        retVal = 'Prepare: Imagine an Elephant';  

    case uint16(movementTypes.LEFT_INDEX_RAISE)
        retVal = 'Prepare: Left Index Raise';  
    case uint16(movementTypes.LEFT_THUMB_UP)
        retVal = 'Prepare: Left Thumb Up';
    case uint16(movementTypes.RIGHT_INDEX_RAISE)
        retVal = 'Prepare: Right Index Raise';  
    case uint16(movementTypes.RIGHT_THUMB_UP)
        retVal = 'Prepare: Right Thumb Up';  
        
    case uint16(movementTypes.LIPS_LEFT)
        retVal = 'Prepare: Lips Left';  
    case uint16(movementTypes.LIPS_RIGHT)
        retVal = 'Prepare: Lips Right';
    case uint16(movementTypes.LIPS_UP)
        retVal = 'Prepare: Lips Up';  
    case uint16(movementTypes.LIPS_DOWN)
        retVal = 'Prepare: Lips Down';  
        
    case uint16(movementTypes.GENERIC_LEFT)
        retVal = 'Prepare: Left';  
    case uint16(movementTypes.GENERIC_RIGHT)
        retVal = 'Prepare: Right';
    case uint16(movementTypes.GENERIC_UP)
        retVal = 'Prepare: Up';  
    case uint16(movementTypes.GENERIC_DOWN)
        retVal = 'Prepare: Down';  
        
    case uint16(movementTypes.BI_LEFT_NO)
        retVal = 'Left                          X';  
    case uint16(movementTypes.BI_RIGHT_NO)
        retVal = 'Right                          X';
    case uint16(movementTypes.BI_UP_NO)
        retVal = 'Up                          X';  
    case uint16(movementTypes.BI_DOWN_NO)
        retVal = 'Down                          X';  
        
    case uint16(movementTypes.BI_NO_LEFT)
        retVal = 'X                          Left';  
    case uint16(movementTypes.BI_NO_RIGHT)
        retVal = 'X                          Right';
    case uint16(movementTypes.BI_NO_UP)
        retVal = 'X                          Up';  
    case uint16(movementTypes.BI_NO_DOWN)
        retVal = 'X                          Down';   
        
    case uint16(movementTypes.BI_LEFT_LEFT)
        retVal = 'Left                          Left';  
    case uint16(movementTypes.BI_LEFT_RIGHT)
        retVal = 'Left                          Right';
    case uint16(movementTypes.BI_LEFT_UP)
        retVal = 'Left                          Up';  
    case uint16(movementTypes.BI_LEFT_DOWN)
        retVal = 'Left                          Down';     
        
    case uint16(movementTypes.BI_RIGHT_LEFT)
        retVal = 'Right                          Left';  
    case uint16(movementTypes.BI_RIGHT_RIGHT)
        retVal = 'Right                          Right';
    case uint16(movementTypes.BI_RIGHT_UP)
        retVal = 'Right                          Up';  
    case uint16(movementTypes.BI_RIGHT_DOWN)
        retVal = 'Right                          Down';     
        
    case uint16(movementTypes.BI_UP_LEFT)
        retVal = 'Up                          Left';  
    case uint16(movementTypes.BI_UP_RIGHT)
        retVal = 'Up                          Right';
    case uint16(movementTypes.BI_UP_UP)
        retVal = 'Up                          Up';  
    case uint16(movementTypes.BI_UP_DOWN)
        retVal = 'Up                          Down';    
        
    case uint16(movementTypes.BI_UP_LEFT)
        retVal = 'Down                          Left';  
    case uint16(movementTypes.BI_UP_RIGHT)
        retVal = 'Down                          Right';
    case uint16(movementTypes.BI_UP_UP)
        retVal = 'Down                          Up';  
    case uint16(movementTypes.BI_UP_DOWN)
        retVal = 'Down                          Down';     
      
    case uint16(movementTypes.SHRUG_AND_ELBOW)
        retVal = 'Prepare: Shoulder Shrug + Elbow In';  
    case uint16(movementTypes.SHRUG_AND_WRIST)
        retVal = 'Prepare: Shoulder Shrug + Wrist Up';
    case uint16(movementTypes.SHRUG_AND_HAND)
        retVal = 'Prepare: Shoulder Shrug + Close Hand';  
    case uint16(movementTypes.ELBOW_AND_WRIST)
        retVal = 'Prepare: Elbow In + Wrist Up';     
    case uint16(movementTypes.ELBOW_AND_HAND)
        retVal = 'Prepare: Elbow In + Close Hand';  
    case uint16(movementTypes.WRIST_AND_HAND)
        retVal = 'Prepare: Wrist Up + Close Hand';                      
  
    case uint16(movementTypes.NOTHING)
        retVal = 'Prepare: Do Nothing';      
        
    otherwise
        retVal = char(zeros([1 50]));
end

retVal2(1:length(retVal)) = retVal;
end