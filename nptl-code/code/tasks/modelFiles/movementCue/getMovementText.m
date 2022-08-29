function retVal2 = getMovementText(moveType)
retVal2 = char(zeros([1 50]));
switch moveType
      
    % Partial Effector Cueing (Ankle, Wrist, Up, Down) DRD 03-26-19
    case uint16(movementTypes.RIGHT_WRIST_FLEX_BOTH)
        retVal = 'Prepare: Wrist Down';
    

    % Right ankle up, right ankle down (Both for partial)  
    case uint16(movementTypes.RIGHT_ANKLE_DORSIFLEX_BOTH)
        retVal = 'Prepare: Ankle Up';
    case uint16(movementTypes.RIGHT_ANKLE_PLANTARFLEX_BOTH)
        retVal = 'Prepare: Ankle Down';    

    % Partial Cueing for Right Wrist effector
    case uint16(movementTypes.RIGHT_WRIST_FLEX_EFFECTOR)
        retVal = 'Prepare: Wrist';
    case uint16(movementTypes.RIGHT_WRIST_EXT_EFFECTOR)
        retVal = 'Prepare: Wrist';    
    
    % Partial Cueing for right and left wrist movement
    case uint16(movementTypes.RIGHT_WRIST_FLEX_MOVEMENT)
        retVal = 'Prepare: Down';
    case uint16(movementTypes.RIGHT_WRIST_EXT_MOVEMENT)
        retVal = 'Prepare: Up';    
        
    % Partial Cueing for Right  Ankle effector
    case uint16(movementTypes.RIGHT_ANKLE_DORSIFLEX_EFFECTOR)
        retVal = 'Prepare: Ankle';
    case uint16(movementTypes.RIGHT_ANKLE_PLANTARFLEX_EFFECTOR)
        retVal = 'Prepare: Ankle';    
  
    % Partial ceuing for right ankle movement    
    case uint16(movementTypes.RIGHT_ANKLE_DORSIFLEX_MOVEMENT)
        retVal = 'Prepare: Up';
    case uint16(movementTypes.RIGHT_ANKLE_PLANTARFLEX_MOVEMENT)
        retVal = 'Prepare: Down';
    
    
        
    case uint16(movementTypes.LEFT_WRIST_EXT_BOTH)
        retVal = 'Prepare: Left Wrist Up';
    case uint16(movementTypes.LEFT_HAND_CLOSE_BOTH)
        retVal = 'Prepare: Left Hand Close';
    case uint16(movementTypes.RIGHT_WRIST_EXT_BOTH)
        retVal = 'Prepare: Wrist Up';
    case uint16(movementTypes.RIGHT_HAND_CLOSE_BOTH)
        retVal = 'Prepare: Right Hand Close';
        
    case uint16(movementTypes.LEFT_WRIST_EXT_EFF)
        retVal = 'Prepare: Left';
    case uint16(movementTypes.LEFT_HAND_CLOSE_EFF)
        retVal = 'Prepare: Left';
    case uint16(movementTypes.RIGHT_WRIST_EXT_EFF)
        retVal = 'Prepare: Right';
    case uint16(movementTypes.RIGHT_HAND_CLOSE_EFF)
        retVal = 'Prepare: Right'; % SDS Sep 2016 changed to "Bicep Flex" from just "Elbow"
    
    case uint16(movementTypes.LEFT_WRIST_EXT_MOV)
        retVal = 'Prepare: Wrist Up';
    case uint16(movementTypes.LEFT_HAND_CLOSE_MOV)
        retVal = 'Prepare: Hand Close';
    case uint16(movementTypes.RIGHT_WRIST_EXT_MOV)
        retVal = 'Prepare: Wrist Up';
    case uint16(movementTypes.RIGHT_HAND_CLOSE_MOV)
        retVal = 'Prepare: Hand Close';

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
        retVal = 'Prepare: Shrug Left Shoulder';
    case uint16(movementTypes.LEFT_ARM_RAISE)
        retVal = 'Prepare: Raise Left Arm';
    case uint16(movementTypes.LEFT_ARM_LOWER)
        retVal = 'Prepare: Lower Left Arm';
    case uint16(movementTypes.LEFT_ELBOW_FLEX)
        retVal = 'Prepare: Flex Left Elbow In';
    case uint16(movementTypes.LEFT_ELBOW_EXT)
        retVal = 'Prepare: Extend Left Elbow Out';
    case uint16(movementTypes.LEFT_WRIST_EXT)
        retVal = 'Prepare: Left Wrist Up';
    case uint16(movementTypes.LEFT_WRIST_FLEX)
        retVal = 'Prepare: Left Wrist Down';
    case uint16(movementTypes.LEFT_CLOSE_HAND)
        retVal = 'Prepare: Close Left Hand';
    case uint16(movementTypes.LEFT_OPEN_HAND)
        retVal = 'Prepare: Open Left Hand';
        
    case uint16(movementTypes.RIGHT_SHO_SHRUG)
        retVal = 'Prepare: Shrug Right Shoulder';
    case uint16(movementTypes.RIGHT_ARM_RAISE)
        retVal = 'Prepare: Raise Right Arm';
    case uint16(movementTypes.RIGHT_ARM_LOWER)
        retVal = 'Prepare: Lower Right Arm';
    case uint16(movementTypes.RIGHT_ELBOW_FLEX)
        retVal = 'Prepare: Flex Right Elbow In';
    case uint16(movementTypes.RIGHT_ELBOW_EXT)
        retVal = 'Prepare: Extend Right Elbow Out';
    case uint16(movementTypes.RIGHT_WRIST_EXT)
        retVal = 'Prepare: Right Wrist Up';
    case uint16(movementTypes.RIGHT_WRIST_FLEX)
        retVal = 'Prepare: Right Wrist Down';
    case uint16(movementTypes.RIGHT_CLOSE_HAND)
        retVal = 'Prepare: Close Right Hand';
    case uint16(movementTypes.RIGHT_OPEN_HAND)
        retVal = 'Prepare: Open Right Hand';
        
    case uint16(movementTypes.LEFT_ANKLE_UP)
        retVal = 'Prepare: Left Ankle Up';
    case uint16(movementTypes.LEFT_ANKLE_DOWN)
        retVal = 'Prepare: Left Ankle Down';
    case uint16(movementTypes.LEFT_KNEE_EXTEND)
        retVal = 'Prepare: Extend Left Knee Out';
    case uint16(movementTypes.LEFT_KNEE_FLEX)
        retVal = 'Prepare: Flex Left Knee In';
    case uint16(movementTypes.LEFT_LEG_UP)
        retVal = 'Prepare: Left Thigh Up';
    case uint16(movementTypes.LEFT_LEG_DOWN)
        retVal = 'Prepare: Left Thigh Down';
    case uint16(movementTypes.LEFT_TOE_CURL)
        retVal = 'Prepare: Curl Left Toes';
    case uint16(movementTypes.LEFT_TOE_OPEN)
        retVal = 'Prepare: Spread Open Left Toes';
        
    case uint16(movementTypes.RIGHT_ANKLE_UP)
        retVal = 'Prepare: Right Ankle Up';
    case uint16(movementTypes.RIGHT_ANKLE_DOWN)
        retVal = 'Prepare: Right Ankle Down';
    case uint16(movementTypes.RIGHT_KNEE_EXTEND)
        retVal = 'Prepare: Extend Right Knee Out';
    case uint16(movementTypes.RIGHT_KNEE_FLEX)
        retVal = 'Prepare: Flex Right Knee In';
    case uint16(movementTypes.RIGHT_LEG_UP)
        retVal = 'Prepare: Right Thigh Up';
    case uint16(movementTypes.RIGHT_LEG_DOWN)
        retVal = 'Prepare: Right Thigh Down';
    case uint16(movementTypes.RIGHT_TOE_CURL)
        retVal = 'Prepare: Curl Right Toes';
    case uint16(movementTypes.RIGHT_TOE_OPEN)
        retVal = 'Prepare: Spread Open Right Toes';

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
        
        
        
        
        
        
   % DRD 
   case uint16(movementTypes.SHOULDER_ABDUCT)
        retVal = 'Prepare: SHOULDER - Arm out to side';
    case uint16(movementTypes.SHOULDER_ADDUCT)
        retVal = 'Prepare: SHOULDER - Arm in to ribs';
    case uint16(movementTypes.SHOULDER_FLEX)
        retVal = 'Prepare: SHOULDER - Arm out in front';
    case uint16(movementTypes.SHOULDER_EXTEND)
        retVal = 'Prepare: SHOULDER - Arm pulled to back';
    case uint16(movementTypes.SHOULDER_EXT_ROT)
        retVal = 'Prepare: SHOULDER - Rotate until fist up';
    case uint16(movementTypes.SHOULDER_INT_ROT)
        retVal = 'Prepare: SHOULDER - Rotate until fist down';
    

    case uint16(movementTypes.WRIST_ULNAR_DEV)
        retVal = 'Prepare: WRIST - Pan Left';
    case uint16(movementTypes.WRIST_RADIAL_DEV)
        retVal = 'Prepare: WRIST - Pan Right';
    case uint16(movementTypes.WRIST_PRO)
        retVal = 'Prepare: WRIST - Rotate palms down';
    case uint16(movementTypes.WRIST_SUP)
        retVal = 'Prepare: WRIST - Rotate palms up';
        
        
    case uint16(movementTypes.HAND_CLOSE)
        retVal = 'Prepare: HAND - Clench fist';
    case uint16(movementTypes.HAND_OPEN)
        retVal = 'Prepare: HAND - Open and spread fingers';
        
        
    case uint16(movementTypes.INDEX_FLEX)
        retVal = 'Prepare: INDEX FINGER - Pull finger in';
    case uint16(movementTypes.INDEX_EXTEND)
        retVal = 'Prepare: INDEX FINGER - Point finger';
%         
%     case uint16(movementTypes.REACH_FRONT)
%         retVal = 'Prepare: Reach out and point in front of you';
%     case uint16(movementTypes.REACH_RIGHT)
%         retVal = 'Prepare: Reach out and point to the right';
%     case uint16(movementTypes.REACH_UP)
%         retVal = 'Prepare: Reach up and point to the sky';
%     case uint16(movementTypes.REACH_NOSE)
%         retVal = 'Prepare: Point finger into nose';
%     case uint16(movementTypes.REACH_HEART)
%         retVal = 'Prepare: Clench fist over heart';
%     case uint16(movementTypes.REACH_BEHIND_HEAD)
%         retVal = 'Prepare: Put hand behind head';
%     case uint16(movementTypes.REACH_STEERING_RIGHT)
%         retVal = 'Prepare: Steering wheel right turn';
%         
    case uint16(movementTypes.JOYSTICK_UP)
        retVal = 'Prepare: HAND JOYSTICK - UP';
    case uint16(movementTypes.JOYSTICK_DOWN)
        retVal = 'Prepare: HAND JOYSTICK - DOWN';
    case uint16(movementTypes.JOYSTICK_LEFT)
        retVal = 'Prepare: HAND JOYSTICK - LEFT';
    case uint16(movementTypes.JOYSTICK_RIGHT)
        retVal = 'Prepare: HAND JOYSTICK - RIGHT';
    
    case uint16(movementTypes.HIP_UP)
        retVal = 'Prepare: HIP - Lift leg up';
    case uint16(movementTypes.KNEE_KICK)
        retVal = 'Prepare: KNEE - Extend';
    case uint16(movementTypes.TOES_SPREAD)
        retVal = 'Prepare: TOES - Spread open';
    case uint16(movementTypes.TOES_CLENCH)
        retVal = 'Prepare: TOES - Curl closed';
    case uint16(movementTypes.BIGTOE_UP)
        retVal = 'Prepare: BIG TOE - Point Up';
    case uint16(movementTypes.BIGTOE_CURL)
        retVal = 'Prepare: BIG TOE - Curl In';
    case uint16(movementTypes.PINKY_EXTEND)
        retVal = 'Prepare: PINKY FINGER - Point Out';
    case uint16(movementTypes.PINKY_FLEX)
        retVal = 'Prepare: PINKY FINGER - Pull In';
    
        
    case uint16(movementTypes.THUMB_EXTEND)
        retVal = 'Prepare: THUMB - Point Up';
    case uint16(movementTypes.THUMB_FLEX)
        retVal = 'Prepare: THUMB - Curl In';
        
    case uint16(movementTypes.PINKYTOE_UP)
        retVal = 'Prepare: PINKY TOE - Point Up';
    case uint16(movementTypes.PINKYTOE_CURL)
        retVal = 'Prepare: PINKY TOE - Curl In';
               
    case uint16(movementTypes.ANKLE_GAS_DOWN)
        retVal = 'Prepare: FOOT JOYSTICK - DOWN';
    case uint16(movementTypes.ANKLE_GAS_UP)
        retVal = 'Prepare: FOOT JOYSTICK - UP';
    case uint16(movementTypes.ANKLE_LEFT)
        retVal = 'Prepare: FOOT JOYSTICK - LEFT';
    case uint16(movementTypes.ANKLE_RIGHT)
        retVal = 'Prepare: FOOT JOYSTICK - RIGHT';
    
    case uint16(movementTypes.DIR_LEFT_HAND_UP)
        retVal = 'Prepare: LEFT HAND - UP';
    case uint16(movementTypes.DIR_LEFT_HAND_DOWN)
        retVal = 'Prepare: LEFT HAND - DOWN';
    case uint16(movementTypes.DIR_LEFT_HAND_RIGHT)
        retVal = 'Prepare: LEFT HAND - RIGHT';
    case uint16(movementTypes.DIR_LEFT_HAND_LEFT)
        retVal = 'Prepare: LEFT HAND - LEFT';
        
    case uint16(movementTypes.DIR_RIGHT_HAND_UP)
        retVal = 'Prepare: RIGHT HAND - UP';
    case uint16(movementTypes.DIR_RIGHT_HAND_DOWN)
        retVal = 'Prepare: RIGHT HAND - DOWN';
    case uint16(movementTypes.DIR_RIGHT_HAND_RIGHT)
        retVal = 'Prepare: RIGHT HAND - RIGHT';
    case uint16(movementTypes.DIR_RIGHT_HAND_LEFT)
        retVal = 'Prepare: RIGHT HAND - LEFT';
        
    case uint16(movementTypes.DIR_LEFT_FOOT_UP)
        retVal = 'Prepare: LEFT FOOT - UP';
    case uint16(movementTypes.DIR_LEFT_FOOT_DOWN)
        retVal = 'Prepare: LEFT FOOT - DOWN';
    case uint16(movementTypes.DIR_LEFT_FOOT_RIGHT)
        retVal = 'Prepare: LEFT FOOT - RIGHT';
    case uint16(movementTypes.DIR_LEFT_FOOT_LEFT)
        retVal = 'Prepare: LEFT FOOT - LEFT';
      
    case uint16(movementTypes.DIR_RIGHT_FOOT_UP)
        retVal = 'Prepare: RIGHT FOOT - UP';
    case uint16(movementTypes.DIR_RIGHT_FOOT_DOWN)
        retVal = 'Prepare: RIGHT FOOT - DOWN';
    case uint16(movementTypes.DIR_RIGHT_FOOT_RIGHT)
        retVal = 'Prepare: RIGHT FOOT - RIGHT';
    case uint16(movementTypes.DIR_RIGHT_FOOT_LEFT)
        retVal = 'Prepare: RIGHT FOOT - LEFT';
      
    case uint16(movementTypes.DIR_LEFT_ARM_UP)
        retVal = 'Prepare: LEFT ARM - UP';
    case uint16(movementTypes.DIR_LEFT_ARM_DOWN)
        retVal = 'Prepare: LEFT ARM - DOWN';
    case uint16(movementTypes.DIR_LEFT_ARM_RIGHT)
        retVal = 'Prepare: LEFT ARM - RIGHT';
    case uint16(movementTypes.DIR_LEFT_ARM_LEFT)
        retVal = 'Prepare: LEFT ARM - LEFT';
        
    case uint16(movementTypes.DIR_RIGHT_ARM_UP)
        retVal = 'Prepare: RIGHT ARM - UP';
    case uint16(movementTypes.DIR_RIGHT_ARM_DOWN)
        retVal = 'Prepare: RIGHT ARM - DOWN';
    case uint16(movementTypes.DIR_RIGHT_ARM_RIGHT)
        retVal = 'Prepare: RIGHT ARM - RIGHT';
    case uint16(movementTypes.DIR_RIGHT_ARM_LEFT)
        retVal = 'Prepare: RIGHT ARM - LEFT';
      
    case uint16(movementTypes.DIR_LEFT_LEG_UP)
        retVal = 'Prepare: LEFT LEG - UP';
    case uint16(movementTypes.DIR_LEFT_LEG_DOWN)
        retVal = 'Prepare: LEFT LEG - DOWN';
    case uint16(movementTypes.DIR_LEFT_LEG_RIGHT)
        retVal = 'Prepare: LEFT LEG - RIGHT';
    case uint16(movementTypes.DIR_LEFT_LEG_LEFT)
        retVal = 'Prepare: LEFT LEG - LEFT';
      
    case uint16(movementTypes.DIR_RIGHT_LEG_UP)
        retVal = 'Prepare: RIGHT LEG - UP';
    case uint16(movementTypes.DIR_RIGHT_LEG_DOWN)
        retVal = 'Prepare: RIGHT LEG - DOWN';
    case uint16(movementTypes.DIR_RIGHT_LEG_RIGHT)
        retVal = 'Prepare: RIGHT LEG - RIGHT';
    case uint16(movementTypes.DIR_RIGHT_LEG_LEFT)
        retVal = 'Prepare: RIGHT LEG - LEFT';
      
    case uint16(movementTypes.DIR_HEAD_UP)
        retVal = 'Prepare: HEAD - UP';
    case uint16(movementTypes.DIR_HEAD_DOWN)
        retVal = 'Prepare: HEAD - DOWN';
    case uint16(movementTypes.DIR_HEAD_RIGHT)
        retVal = 'Prepare: HEAD - RIGHT';
    case uint16(movementTypes.DIR_HEAD_LEFT)
        retVal = 'Prepare: HEAD - LEFT';
      
    case uint16(movementTypes.DIR_TONGUE_UP)
        retVal = 'Prepare: TONGUE - UP';
    case uint16(movementTypes.DIR_TONGUE_DOWN)
        retVal = 'Prepare: TONGUE - DOWN';
    case uint16(movementTypes.DIR_TONGUE_RIGHT)
        retVal = 'Prepare: TONGUE - RIGHT';
    case uint16(movementTypes.DIR_TONGUE_LEFT)
        retVal = 'Prepare: TONGUE - LEFT';
        
    %Grasp force
    case uint16(movementTypes.GRASP_FORCE_LIGHT)
        retVal = 'Prepare: GRASP - LIGHT';
    case uint16(movementTypes.GRASP_FORCE_MEDIUM)
        retVal = 'Prepare: GRASP - MEDIUM';
    case uint16(movementTypes.GRASP_FORCE_HARD)
        retVal = 'Prepare: GRASP - HARD';
                     
    %Letter writing
    case uint16(movementTypes.LETTER_A)
        retVal = 'Prepare: a';
    case uint16(movementTypes.LETTER_B)
        retVal = 'Prepare: b';
    case uint16(movementTypes.LETTER_C)
        retVal = 'Prepare: c';
    case uint16(movementTypes.LETTER_D)
        retVal = 'Prepare: d';
    case uint16(movementTypes.LETTER_T)
        retVal = 'Prepare: t';
    case uint16(movementTypes.LETTER_M)
        retVal = 'Prepare: m';
    case uint16(movementTypes.LETTER_O)
        retVal = 'Prepare: o';
        
    case uint16(movementTypes.LETTER_E)
        retVal = 'Prepare: e';
    case uint16(movementTypes.LETTER_F)
        retVal = 'Prepare: f';
    case uint16(movementTypes.LETTER_G)
        retVal = 'Prepare: g';
    case uint16(movementTypes.LETTER_H)
        retVal = 'Prepare: h';
    case uint16(movementTypes.LETTER_I)
        retVal = 'Prepare: i';
    case uint16(movementTypes.LETTER_J)
        retVal = 'Prepare: j';
    case uint16(movementTypes.LETTER_K)
        retVal = 'Prepare: k';
    case uint16(movementTypes.LETTER_L)
        retVal = 'Prepare: l';
    case uint16(movementTypes.LETTER_N)
        retVal = 'Prepare: n';
    case uint16(movementTypes.LETTER_P)
        retVal = 'Prepare: p';
    case uint16(movementTypes.LETTER_Q)
        retVal = 'Prepare: q';
    case uint16(movementTypes.LETTER_R)
        retVal = 'Prepare: r';
    case uint16(movementTypes.LETTER_S)
        retVal = 'Prepare: s';
    case uint16(movementTypes.LETTER_U)
        retVal = 'Prepare: u';
    case uint16(movementTypes.LETTER_V)
        retVal = 'Prepare: v';
    case uint16(movementTypes.LETTER_W)
        retVal = 'Prepare: w';
    case uint16(movementTypes.LETTER_X)
        retVal = 'Prepare: x';
    case uint16(movementTypes.LETTER_Y)
        retVal = 'Prepare: y';
    case uint16(movementTypes.LETTER_Z)
        retVal = 'Prepare: z';
    case uint16(movementTypes.LETTER_DASH)
        retVal = 'Prepare: -';
    case uint16(movementTypes.LETTER_GREATER)
        retVal = 'Prepare: >';
        
    case uint16(movementTypes.LETTER_CAT)
        retVal = 'Prepare: cat';
    case uint16(movementTypes.LETTER_BAT)
        retVal = 'Prepare: bat';
    case uint16(movementTypes.LETTER_BOMB)
        retVal = 'Prepare: bomb';
    case uint16(movementTypes.LETTER_TOM)
        retVal = 'Prepare: tom';
    case uint16(movementTypes.LETTER_MAT)
        retVal = 'Prepare: mat';
        
    case uint16(movementTypes.LETTER_LOGICAL_AND)
        retVal = 'Prepare: ^';
    case uint16(movementTypes.LETTER_INFINITY)
        retVal = 'Prepare: inf';
    case uint16(movementTypes.LETTER_BOX_HORZ)
        retVal = 'Prepare: -';
    case uint16(movementTypes.LETTER_BOX_VERT)
        retVal = 'Prepare: |';
    case uint16(movementTypes.LETTER_DYNAMICAL_EIGHT)
        retVal = 'Prepare: 8';
    case uint16(movementTypes.LETTER_DYNAMICAL_GREATER)
        retVal = 'Prepare: >';
    case uint16(movementTypes.LETTER_DYNAMICAL_O)
        retVal = 'Prepare: o';
        
    case uint16(movementTypes.LETTER_A_SIZE_1_SPEED_1)
        retVal = 'Prepare: a - small - slow';
    case uint16(movementTypes.LETTER_A_SIZE_2_SPEED_1)
        retVal = 'Prepare: a - medium - slow';
    case uint16(movementTypes.LETTER_A_SIZE_3_SPEED_1)
        retVal = 'Prepare: a - big - slow';

    case uint16(movementTypes.LETTER_A_SIZE_1_SPEED_2)
        retVal = 'Prepare: a - small - medium';
    case uint16(movementTypes.LETTER_A_SIZE_2_SPEED_2)
        retVal = 'Prepare: a - medium - medium';
    case uint16(movementTypes.LETTER_A_SIZE_3_SPEED_2)
        retVal = 'Prepare: a - big - medium';
        
    case uint16(movementTypes.LETTER_A_SIZE_1_SPEED_3)
        retVal = 'Prepare: a - small - fast';
    case uint16(movementTypes.LETTER_A_SIZE_2_SPEED_3)
        retVal = 'Prepare: a - medium - fast';
    case uint16(movementTypes.LETTER_A_SIZE_3_SPEED_3)
        retVal = 'Prepare: a - big - fast';
        
    case uint16(movementTypes.LETTER_M_SIZE_1_SPEED_1)
        retVal = 'Prepare: m - small - slow';
    case uint16(movementTypes.LETTER_M_SIZE_2_SPEED_1)
        retVal = 'Prepare: m - medium - slow';
    case uint16(movementTypes.LETTER_M_SIZE_3_SPEED_1)
        retVal = 'Prepare: m - big - slow';

    case uint16(movementTypes.LETTER_M_SIZE_1_SPEED_2)
        retVal = 'Prepare: m - small - medium';
    case uint16(movementTypes.LETTER_M_SIZE_2_SPEED_2)
        retVal = 'Prepare: m - medium - medium';
    case uint16(movementTypes.LETTER_M_SIZE_3_SPEED_2)
        retVal = 'Prepare: m - big - medium';
        
    case uint16(movementTypes.LETTER_M_SIZE_1_SPEED_3)
        retVal = 'Prepare: m - small - fast';
    case uint16(movementTypes.LETTER_M_SIZE_2_SPEED_3)
        retVal = 'Prepare: m - medium - fast';
    case uint16(movementTypes.LETTER_M_SIZE_3_SPEED_3)
        retVal = 'Prepare: m - big - fast';
        
    case uint16(movementTypes.LETTER_Z_SIZE_1_SPEED_1)
        retVal = 'Prepare: z - small - slow';
    case uint16(movementTypes.LETTER_Z_SIZE_2_SPEED_1)
        retVal = 'Prepare: z - medium - slow';
    case uint16(movementTypes.LETTER_Z_SIZE_3_SPEED_1)
        retVal = 'Prepare: z - big - slow';

    case uint16(movementTypes.LETTER_Z_SIZE_1_SPEED_2)
        retVal = 'Prepare: z - small - medium';
    case uint16(movementTypes.LETTER_Z_SIZE_2_SPEED_2)
        retVal = 'Prepare: z - medium - medium';
    case uint16(movementTypes.LETTER_Z_SIZE_3_SPEED_2)
        retVal = 'Prepare: z - big - medium';
        
    case uint16(movementTypes.LETTER_Z_SIZE_1_SPEED_3)
        retVal = 'Prepare: z - small - fast';
    case uint16(movementTypes.LETTER_Z_SIZE_2_SPEED_3)
        retVal = 'Prepare: z - medium - fast';
    case uint16(movementTypes.LETTER_Z_SIZE_3_SPEED_3)
        retVal = 'Prepare: z - big - fast';
        
    case uint16(movementTypes.LETTER_T_SIZE_1_SPEED_1)
        retVal = 'Prepare: t - small - slow';
    case uint16(movementTypes.LETTER_T_SIZE_2_SPEED_1)
        retVal = 'Prepare: t - medium - slow';
    case uint16(movementTypes.LETTER_T_SIZE_3_SPEED_1)
        retVal = 'Prepare: t - big - slow';

    case uint16(movementTypes.LETTER_T_SIZE_1_SPEED_2)
        retVal = 'Prepare: t - small - medium';
    case uint16(movementTypes.LETTER_T_SIZE_2_SPEED_2)
        retVal = 'Prepare: t - medium - medium';
    case uint16(movementTypes.LETTER_T_SIZE_3_SPEED_2)
        retVal = 'Prepare: t - big - medium';
        
    case uint16(movementTypes.LETTER_T_SIZE_1_SPEED_3)
        retVal = 'Prepare: t - small - fast';
    case uint16(movementTypes.LETTER_T_SIZE_2_SPEED_3)
        retVal = 'Prepare: t - medium - fast';
    case uint16(movementTypes.LETTER_T_SIZE_3_SPEED_3)
        retVal = 'Prepare: t - big - fast';
        
    case uint16(movementTypes.LETTER_NT)
        retVal = 'Prepare: nt';
    case uint16(movementTypes.LETTER_LT)
        retVal = 'Prepare: lt';
    case uint16(movementTypes.LETTER_OT)
        retVal = 'Prepare: ot';  
    case uint16(movementTypes.LETTER_UT)
        retVal = 'Prepare: ut';
    case uint16(movementTypes.LETTER_TT)
        retVal = 'Prepare: tt';
    case uint16(movementTypes.LETTER_DT)
        retVal = 'Prepare: dt';  
        
    case uint16(movementTypes.LETTER_NO)
        retVal = 'Prepare: no';
    case uint16(movementTypes.LETTER_LO)
        retVal = 'Prepare: lo';
    case uint16(movementTypes.LETTER_OO)
        retVal = 'Prepare: oo';  
    case uint16(movementTypes.LETTER_UO)
        retVal = 'Prepare: uo';
    case uint16(movementTypes.LETTER_TO)
        retVal = 'Prepare: to';
    case uint16(movementTypes.LETTER_DO)
        retVal = 'Prepare: do';  
         
    % Word sets cues
    % SET 1:
    case uint16(movementTypes.WORDS_BACK)
        retVal = 'Prepare: "Back"';
    case uint16(movementTypes.WORDS_BAD)
        retVal = 'Prepare: "Bad"';
    case uint16(movementTypes.WORDS_BEAT)
        retVal = 'Prepare: "Beat"';
    case uint16(movementTypes.WORDS_BED)
        retVal = 'Prepare: "Bed"';
    case uint16(movementTypes.WORDS_BELL)
        retVal = 'Prepare: "Bell"';
    case uint16(movementTypes.WORDS_BENT)
        retVal = 'Prepare: "Bent"';
    case uint16(movementTypes.WORDS_BIG)
        retVal = 'Prepare: "Big"';
    case uint16(movementTypes.WORDS_BITE)
        retVal = 'Prepare: "Bite"';
    case uint16(movementTypes.WORDS_BOON)
        retVal = 'Prepare: "Boon"';
    case uint16(movementTypes.WORDS_BOSS)
        retVal = 'Prepare: "Boss"';
    case uint16(movementTypes.WORDS_BOUT)
        retVal = 'Prepare: "Bout"';
    case uint16(movementTypes.WORDS_BOY)
        retVal = 'Prepare: "Boy"';
    case uint16(movementTypes.WORDS_BUN)
        retVal = 'Prepare: "Bun"';
    case uint16(movementTypes.WORDS_BURN)
        retVal = 'Prepare: "Burn"';
    case uint16(movementTypes.WORDS_BUS)
        retVal = 'Prepare: "Bus"';
    case uint16(movementTypes.WORDS_CANE)
        retVal = 'Prepare: "Cane"';
    case uint16(movementTypes.WORDS_CASE)
        retVal = 'Prepare: "Case"';
    case uint16(movementTypes.WORDS_COIL)
        retVal = 'Prepare: "Coil"';
    case uint16(movementTypes.WORDS_COIN)
        retVal = 'Prepare: "Coin"';
    case uint16(movementTypes.WORDS_COLD)
        retVal = 'Prepare: "Cold"';
    case uint16(movementTypes.WORDS_COOK)
        retVal = 'Prepare: "Cook"';
    case uint16(movementTypes.WORDS_COOL)
        retVal = 'Prepare: "Cool"';
    case uint16(movementTypes.WORDS_COP)
        retVal = 'Prepare: "Cop"';
    case uint16(movementTypes.WORDS_COT)
        retVal = 'Prepare: "Cot"';
    case uint16(movementTypes.WORDS_COW)
        retVal = 'Prepare: "Cow"';
    case uint16(movementTypes.WORDS_CUD)
        retVal = 'Prepare: "Cud"';
    case uint16(movementTypes.WORDS_CUT)
        retVal = 'Prepare: "Cut"';
    case uint16(movementTypes.WORDS_DARK)
        retVal = 'Prepare: "Dark"';
    case uint16(movementTypes.WORDS_DEN)
        retVal = 'Prepare: "Den"';
    case uint16(movementTypes.WORDS_DIG)
        retVal = 'Prepare: "Dig"';
    case uint16(movementTypes.WORDS_DIM)
        retVal = 'Prepare: "Dim"';
    case uint16(movementTypes.WORDS_DINE)
        retVal = 'Prepare: "Dine"';
    case uint16(movementTypes.WORDS_DOG)
        retVal = 'Prepare: "Dog"';
    case uint16(movementTypes.WORDS_DOLL)
        retVal = 'Prepare: "Doll"';
    case uint16(movementTypes.WORDS_DUCK)
        retVal = 'Prepare: "Duck"';
    case uint16(movementTypes.WORDS_DUPE)
        retVal = 'Prepare: "Dupe"';
    case uint16(movementTypes.WORDS_FAWN)
        retVal = 'Prepare: "Fawn"';
    case uint16(movementTypes.WORDS_FEAT)
        retVal = 'Prepare: "Feat"';
    case uint16(movementTypes.WORDS_FED)
        retVal = 'Prepare: "Fed"';
    case uint16(movementTypes.WORDS_FEEL)
        retVal = 'Prepare: "Feel"';
    case uint16(movementTypes.WORDS_FIT)
        retVal = 'Prepare: "Fit"';
    case uint16(movementTypes.WORDS_FOB)
        retVal = 'Prepare: "Fob"';
    case uint16(movementTypes.WORDS_FOLD)
        retVal = 'Prepare: "Fold"';
    case uint16(movementTypes.WORDS_FOOT)
        retVal = 'Prepare: "Foot"';
    case uint16(movementTypes.WORDS_FULL)
        retVal = 'Prepare: "Full"';
    case uint16(movementTypes.WORDS_GALE)
        retVal = 'Prepare: "Gale"';
    case uint16(movementTypes.WORDS_GAME)
        retVal = 'Prepare: "Game"';
    case uint16(movementTypes.WORDS_GOAT)
        retVal = 'Prepare: "Goat"';
    case uint16(movementTypes.WORDS_GOT)
        retVal = 'Prepare: "Got"';
    case uint16(movementTypes.WORDS_HOOT)
        retVal = 'Prepare: "Hoot"';
    case uint16(movementTypes.WORDS_KICK)
        retVal = 'Prepare: "Kick"';
    case uint16(movementTypes.WORDS_KIT)
        retVal = 'Prepare: "Kit"';
    case uint16(movementTypes.WORDS_LAKE)
        retVal = 'Prepare: "Lake"';
    case uint16(movementTypes.WORDS_LAW)
        retVal = 'Prepare: "Law"';
    case uint16(movementTypes.WORDS_LAWN)
        retVal = 'Prepare: "Lawn"';
    case uint16(movementTypes.WORDS_LED)
        retVal = 'Prepare: "Led"';
    case uint16(movementTypes.WORDS_LOAN)
        retVal = 'Prepare: "Loan"';
    case uint16(movementTypes.WORDS_LOOK)
        retVal = 'Prepare: "Look"';
    case uint16(movementTypes.WORDS_LOON)
        retVal = 'Prepare: "Loon"';
    case uint16(movementTypes.WORDS_MAP)
        retVal = 'Prepare: "Map"';
    case uint16(movementTypes.WORDS_MARK)
        retVal = 'Prepare: "Mark"';
    case uint16(movementTypes.WORDS_MAY)
        retVal = 'Prepare: "May"';
    case uint16(movementTypes.WORDS_MICE)
        retVal = 'Prepare: "Mice"';
    case uint16(movementTypes.WORDS_MOON)
        retVal = 'Prepare: "Moon"';
    case uint16(movementTypes.WORDS_MOP)
        retVal = 'Prepare: "Mop"';
    case uint16(movementTypes.WORDS_MOUSE)
        retVal = 'Prepare: "Mouse"';
    case uint16(movementTypes.WORDS_NAME)
        retVal = 'Prepare: "Name"';
    case uint16(movementTypes.WORDS_NEAT)
        retVal = 'Prepare: "Neat"';
    case uint16(movementTypes.WORDS_NOT)
        retVal = 'Prepare: "Not"';
    case uint16(movementTypes.WORDS_OIL)
        retVal = 'Prepare: "Oil"';
    case uint16(movementTypes.WORDS_PACE)
        retVal = 'Prepare: "Pace"';
    case uint16(movementTypes.WORDS_PAD)
        retVal = 'Prepare: "Pad"';
    case uint16(movementTypes.WORDS_PAN)
        retVal = 'Prepare: "Pan"';
    case uint16(movementTypes.WORDS_PAT)
        retVal = 'Prepare: "Pat"';
    case uint16(movementTypes.WORDS_PAWN)
        retVal = 'Prepare: "Pawn"';
    case uint16(movementTypes.WORDS_PEACE)
        retVal = 'Prepare: "Peace"';
    case uint16(movementTypes.WORDS_PEAK)
        retVal = 'Prepare: "Peak"';
    case uint16(movementTypes.WORDS_PEARL)
        retVal = 'Prepare: "Pearl"';
    case uint16(movementTypes.WORDS_PIG)
        retVal = 'Prepare: "Pig"';
    case uint16(movementTypes.WORDS_PIN)
        retVal = 'Prepare: "Pin"';
    case uint16(movementTypes.WORDS_PINE)
        retVal = 'Prepare: "Pine"';
    case uint16(movementTypes.WORDS_POOL)
        retVal = 'Prepare: "Pool"';
    case uint16(movementTypes.WORDS_PUB)
        retVal = 'Prepare: "Pub"';
    case uint16(movementTypes.WORDS_PUCK)
        retVal = 'Prepare: "Puck"';
    case uint16(movementTypes.WORDS_PUFF)
        retVal = 'Prepare: "Puff"';
    case uint16(movementTypes.WORDS_PULL)
        retVal = 'Prepare: "Pull"';
    case uint16(movementTypes.WORDS_RATE)
        retVal = 'Prepare: "Rate"';
    case uint16(movementTypes.WORDS_RAW)
        retVal = 'Prepare: "Raw"';
    case uint16(movementTypes.WORDS_REEL)
        retVal = 'Prepare: "Reel"';
    case uint16(movementTypes.WORDS_REST)
        retVal = 'Prepare: "Rest"';
    case uint16(movementTypes.WORDS_RYE)
        retVal = 'Prepare: "Rye"';
    case uint16(movementTypes.WORDS_SAG)
        retVal = 'Prepare: "Sag"';
    case uint16(movementTypes.WORDS_SALE)
        retVal = 'Prepare: "Sale"';
    case uint16(movementTypes.WORDS_SAME)
        retVal = 'Prepare: "Same"';
    case uint16(movementTypes.WORDS_SASS)
        retVal = 'Prepare: "Sass"';
    case uint16(movementTypes.WORDS_SAT)
        retVal = 'Prepare: "Sat"';
    case uint16(movementTypes.WORDS_SEEN)
        retVal = 'Prepare: "Seen"';
    case uint16(movementTypes.WORDS_SEEP)
        retVal = 'Prepare: "Seep"';
    case uint16(movementTypes.WORDS_SEWN)
        retVal = 'Prepare: "Sewn"';
    case uint16(movementTypes.WORDS_SICK)
        retVal = 'Prepare: "Sick"';
    case uint16(movementTypes.WORDS_SIP)
        retVal = 'Prepare: "Sip"';
    case uint16(movementTypes.WORDS_SOIL)
        retVal = 'Prepare: "Soil"';
    case uint16(movementTypes.WORDS_SOON)
        retVal = 'Prepare: "Soon"';
    case uint16(movementTypes.WORDS_SOUL)
        retVal = 'Prepare: "Soul"';
    case uint16(movementTypes.WORDS_SOUP)
        retVal = 'Prepare: "Soup"';
    case uint16(movementTypes.WORDS_SUM)
        retVal = 'Prepare: "Sum"';
    case uint16(movementTypes.WORDS_SUN)
        retVal = 'Prepare: "Sun"';
    case uint16(movementTypes.WORDS_TAP)
        retVal = 'Prepare: "Tap"';
    case uint16(movementTypes.WORDS_TEAK)
        retVal = 'Prepare: "Teak"';
    case uint16(movementTypes.WORDS_TEAL)
        retVal = 'Prepare: "Teal"';
    case uint16(movementTypes.WORDS_TEAM)
        retVal = 'Prepare: "Team"';
    case uint16(movementTypes.WORDS_TERSE)
        retVal = 'Prepare: "Terse"';
    case uint16(movementTypes.WORDS_TIGHT)
        retVal = 'Prepare: "Tight"';
    case uint16(movementTypes.WORDS_TOLL)
        retVal = 'Prepare: "Toll"';
    case uint16(movementTypes.WORDS_TOOK)
        retVal = 'Prepare: "Took"';
    case uint16(movementTypes.WORDS_TOWN)
        retVal = 'Prepare: "Town"';
    case uint16(movementTypes.WORDS_TURN)
        retVal = 'Prepare: "Turn"';
    case uint16(movementTypes.WORDS_WILL)
        retVal = 'Prepare: "Will"';
       
        % SET 2
    case uint16(movementTypes.WORDS_BAN)
        retVal = 'Prepare: "Ban"';
    case uint16(movementTypes.WORDS_BAR)
        retVal = 'Prepare: "Bar"';
    case uint16(movementTypes.WORDS_BASS)
        retVal = 'Prepare: "Bass"';
    case uint16(movementTypes.WORDS_BAT)
        retVal = 'Prepare: "Bat"';
    case uint16(movementTypes.WORDS_BEAD)
        retVal = 'Prepare: "Bead"';
    case uint16(movementTypes.WORDS_BEAK)
        retVal = 'Prepare: "Beak"';
    case uint16(movementTypes.WORDS_BEAM)
        retVal = 'Prepare: "Beam"';
    case uint16(movementTypes.WORDS_BEST)
        retVal = 'Prepare: "Best"';
    case uint16(movementTypes.WORDS_BOAT)
        retVal = 'Prepare: "Boat"';
    case uint16(movementTypes.WORDS_BOIL)
        retVal = 'Prepare: "Boil"';
    case uint16(movementTypes.WORDS_BOOK)
        retVal = 'Prepare: "Book"';
    case uint16(movementTypes.WORDS_BUCK)
        retVal = 'Prepare: "Buck"';
    case uint16(movementTypes.WORDS_BUFF)
        retVal = 'Prepare: "Buff"';
    case uint16(movementTypes.WORDS_BUG)
        retVal = 'Prepare: "Bug"';
    case uint16(movementTypes.WORDS_BULL)
        retVal = 'Prepare: "Bull"';
    case uint16(movementTypes.WORDS_CAKE)
        retVal = 'Prepare: "Cake"';
    case uint16(movementTypes.WORDS_CAME)
        retVal = 'Prepare: "Came"';
    case uint16(movementTypes.WORDS_COMB)
        retVal = 'Prepare: "Comb"';
    case uint16(movementTypes.WORDS_CUFF)
        retVal = 'Prepare: "Cuff"';
    case uint16(movementTypes.WORDS_CUSS)
        retVal = 'Prepare: "Cuss"';
    case uint16(movementTypes.WORDS_DAWN)
        retVal = 'Prepare: "Dawn"';
    case uint16(movementTypes.WORDS_DIN)
        retVal = 'Prepare: "Din"';
    case uint16(movementTypes.WORDS_DIP)
        retVal = 'Prepare: "Dip"';
    case uint16(movementTypes.WORDS_DOWN)
        retVal = 'Prepare: "Down"';
    case uint16(movementTypes.WORDS_DUB)
        retVal = 'Prepare: "Dub"';
    case uint16(movementTypes.WORDS_DUD)
        retVal = 'Prepare: "Dud"';
    case uint16(movementTypes.WORDS_DUDE)
        retVal = 'Prepare: "Dude"';
    case uint16(movementTypes.WORDS_DUST)
        retVal = 'Prepare: "Dust"';
    case uint16(movementTypes.WORDS_FALL)
        retVal = 'Prepare: "Fall"';
    case uint16(movementTypes.WORDS_FERN)
        retVal = 'Prepare: "Fern"';
    case uint16(movementTypes.WORDS_FIG)
        retVal = 'Prepare: "Fig"';
    case uint16(movementTypes.WORDS_FINE)
        retVal = 'Prepare: "Fine"';
    case uint16(movementTypes.WORDS_FOAM)
        retVal = 'Prepare: "Foam"';
    case uint16(movementTypes.WORDS_FOIL)
        retVal = 'Prepare: "Foil"';
    case uint16(movementTypes.WORDS_GAY)
        retVal = 'Prepare: "Gay"';
    case uint16(movementTypes.WORDS_GOD)
        retVal = 'Prepare: "God"';
    case uint16(movementTypes.WORDS_GUN)
        retVal = 'Prepare: "Gun"';
    case uint16(movementTypes.WORDS_HEAP)
        retVal = 'Prepare: "Heap"';
    case uint16(movementTypes.WORDS_HEEL)
        retVal = 'Prepare: "Heel"';
    case uint16(movementTypes.WORDS_HILL)
        retVal = 'Prepare: "Hill"';
    case uint16(movementTypes.WORDS_HOT)
        retVal = 'Prepare: "Hot"';
    case uint16(movementTypes.WORDS_KEEL)
        retVal = 'Prepare: "Keel"';
    case uint16(movementTypes.WORDS_KID)
        retVal = 'Prepare: "Kid"';
    case uint16(movementTypes.WORDS_LACE)
        retVal = 'Prepare: "Lace"';
    case uint16(movementTypes.WORDS_LAME)
        retVal = 'Prepare: "Lame"';
    case uint16(movementTypes.WORDS_LICK)
        retVal = 'Prepare: "Lick"';
    case uint16(movementTypes.WORDS_LIKE)
        retVal = 'Prepare: "Like"';
    case uint16(movementTypes.WORDS_LIP)
        retVal = 'Prepare: "Lip"';
    case uint16(movementTypes.WORDS_LOOT)
        retVal = 'Prepare: "Loot"';
    case uint16(movementTypes.WORDS_MAD)
        retVal = 'Prepare: "Mad"';
    case uint16(movementTypes.WORDS_MAN)
        retVal = 'Prepare: "Man"';
    case uint16(movementTypes.WORDS_MEAT)
        retVal = 'Prepare: "Meat"';
    case uint16(movementTypes.WORDS_MILE)
        retVal = 'Prepare: "Mile"';
    case uint16(movementTypes.WORDS_MOAT)
        retVal = 'Prepare: "Moat"';
    case uint16(movementTypes.WORDS_NEST)
        retVal = 'Prepare: "Nest"';
    case uint16(movementTypes.WORDS_NOON)
        retVal = 'Prepare: "Noon"';
    case uint16(movementTypes.WORDS_NOW)
        retVal = 'Prepare: "Now"';
    case uint16(movementTypes.WORDS_PACK)
        retVal = 'Prepare: "Pack"';
    case uint16(movementTypes.WORDS_PALE)
        retVal = 'Prepare: "Pale"';
    case uint16(movementTypes.WORDS_PANE)
        retVal = 'Prepare: "Pane"';
    case uint16(movementTypes.WORDS_PARK)
        retVal = 'Prepare: "Park"';
    case uint16(movementTypes.WORDS_PASS)
        retVal = 'Prepare: "Pass"';
    case uint16(movementTypes.WORDS_PAW)
        retVal = 'Prepare: "Paw"';
    case uint16(movementTypes.WORDS_PAY)
        retVal = 'Prepare: "Pay"';
    case uint16(movementTypes.WORDS_PEAT)
        retVal = 'Prepare: "Peat"';
    case uint16(movementTypes.WORDS_PICK)
        retVal = 'Prepare: "Pick"';
    case uint16(movementTypes.WORDS_PIP)
        retVal = 'Prepare: "Pip"';
    case uint16(movementTypes.WORDS_PIPE)
        retVal = 'Prepare: "Pipe"';
    case uint16(movementTypes.WORDS_PIT)
        retVal = 'Prepare: "Pit"';
    case uint16(movementTypes.WORDS_POCK)
        retVal = 'Prepare: "Pock"';
    case uint16(movementTypes.WORDS_POLL)
        retVal = 'Prepare: "Poll"';
    case uint16(movementTypes.WORDS_POT)
        retVal = 'Prepare: "Pot"';
    case uint16(movementTypes.WORDS_PUN)
        retVal = 'Prepare: "Pun"';
    case uint16(movementTypes.WORDS_PUP)
        retVal = 'Prepare: "Pup"';
    case uint16(movementTypes.WORDS_PUS)
        retVal = 'Prepare: "Pus"';
    case uint16(movementTypes.WORDS_RAKE)
        retVal = 'Prepare: "Rake"';
    case uint16(movementTypes.WORDS_RED)
        retVal = 'Prepare: "Red"';
    case uint16(movementTypes.WORDS_RENT)
        retVal = 'Prepare: "Rent"';
    case uint16(movementTypes.WORDS_RICE)
        retVal = 'Prepare: "Rice"';
    case uint16(movementTypes.WORDS_RIG)
        retVal = 'Prepare: "Rig"';
    case uint16(movementTypes.WORDS_RIP)
        retVal = 'Prepare: "Rip"';
    case uint16(movementTypes.WORDS_RUN)
        retVal = 'Prepare: "Run"';
    case uint16(movementTypes.WORDS_RUST)
        retVal = 'Prepare: "Rust"';
    case uint16(movementTypes.WORDS_SACK)
        retVal = 'Prepare: "Sack"';
    case uint16(movementTypes.WORDS_SAD)
        retVal = 'Prepare: "Sad"';
    case uint16(movementTypes.WORDS_SAFE)
        retVal = 'Prepare: "Safe"';
    case uint16(movementTypes.WORDS_SAKE)
        retVal = 'Prepare: "Sake"';
    case uint16(movementTypes.WORDS_SANE)
        retVal = 'Prepare: "Sane"';
    case uint16(movementTypes.WORDS_SAP)
        retVal = 'Prepare: "Sap"';
    case uint16(movementTypes.WORDS_SAW)
        retVal = 'Prepare: "Saw"';
    case uint16(movementTypes.WORDS_SEAT)
        retVal = 'Prepare: "Seat"';
    case uint16(movementTypes.WORDS_SEEK)
        retVal = 'Prepare: "Seek"';
    case uint16(movementTypes.WORDS_SEEM)
        retVal = 'Prepare: "Seem"';
    case uint16(movementTypes.WORDS_SIN)
        retVal = 'Prepare: "Sin"';
    case uint16(movementTypes.WORDS_SIT)
        retVal = 'Prepare: "Sit"';
    case uint16(movementTypes.WORDS_SOLD)
        retVal = 'Prepare: "Sold"';
    case uint16(movementTypes.WORDS_SUB)
        retVal = 'Prepare: "Sub"';
    case uint16(movementTypes.WORDS_SUD)
        retVal = 'Prepare: "Sud"';
    case uint16(movementTypes.WORDS_SUED)
        retVal = 'Prepare: "Sued"';
    case uint16(movementTypes.WORDS_SUP)
        retVal = 'Prepare: "Sup"';
    case uint16(movementTypes.WORDS_TAB)
        retVal = 'Prepare: "Tab"';
    case uint16(movementTypes.WORDS_TACK)
        retVal = 'Prepare: "Tack"';
    case uint16(movementTypes.WORDS_TALE)
        retVal = 'Prepare: "Tale"';
    case uint16(movementTypes.WORDS_TAM)
        retVal = 'Prepare: "Tam"';
    case uint16(movementTypes.WORDS_TAME)
        retVal = 'Prepare: "Tame"';
    case uint16(movementTypes.WORDS_TEAR)
        retVal = 'Prepare: "Tear"';
    case uint16(movementTypes.WORDS_TEN)
        retVal = 'Prepare: "Ten"';
    case uint16(movementTypes.WORDS_TICK)
        retVal = 'Prepare: "Tick"';
    case uint16(movementTypes.WORDS_TOIL)
        retVal = 'Prepare: "Toil"';
    case uint16(movementTypes.WORDS_TOOL)
        retVal = 'Prepare: "Tool"';
    case uint16(movementTypes.WORDS_TOP)
        retVal = 'Prepare: "Top"';
    case uint16(movementTypes.WORDS_TYPE)
        retVal = 'Prepare: "Type"';
    case uint16(movementTypes.WORDS_WED)
        retVal = 'Prepare: "Wed"';
    case uint16(movementTypes.WORDS_WHITE)
        retVal = 'Prepare: "White"';
    case uint16(movementTypes.WORDS_WIG)
        retVal = 'Prepare: "Wig"';
    case uint16(movementTypes.WORDS_WOOL)
        retVal = 'Prepare: "Wool"';
        
    % SET 3
    case uint16(movementTypes.WORDS_ASIA)
        retVal = 'Prepare: "Asia"';
    case uint16(movementTypes.WORDS_BANG)
        retVal = 'Prepare: "Bang"';
    case uint16(movementTypes.WORDS_BATH)
        retVal = 'Prepare: "Bath"';
    case uint16(movementTypes.WORDS_BEIGE)
        retVal = 'Prepare: "Beige"';
    case uint16(movementTypes.WORDS_BOTH)
        retVal = 'Prepare: "Both"';
    case uint16(movementTypes.WORDS_CASH)
        retVal = 'Prepare: "Cash"';
    case uint16(movementTypes.WORDS_CAVE)
        retVal = 'Prepare: "Cave"';
    case uint16(movementTypes.WORDS_DUNG)
        retVal = 'Prepare: "Dung"';
    case uint16(movementTypes.WORDS_FAITH)
        retVal = 'Prepare: "Faith"';
    case uint16(movementTypes.WORDS_FANG)
        retVal = 'Prepare: "Fang"';
    case uint16(movementTypes.WORDS_FISH)
        retVal = 'Prepare: "Fish"';
    case uint16(movementTypes.WORDS_FIZZ)
        retVal = 'Prepare: "Fizz"';
    case uint16(movementTypes.WORDS_GANG)
        retVal = 'Prepare: "Gang"';
    case uint16(movementTypes.WORDS_GARAGE)
        retVal = 'Prepare: "Garage"';
    case uint16(movementTypes.WORDS_GENRE)
        retVal = 'Prepare: "Genre"';
    case uint16(movementTypes.WORDS_GIVE)
        retVal = 'Prepare: "Give"';
    case uint16(movementTypes.WORDS_GOSH)
        retVal = 'Prepare: "Gosh"';
    case uint16(movementTypes.WORDS_GOTH)
        retVal = 'Prepare: "Goth"';
    case uint16(movementTypes.WORDS_HANG)
        retVal = 'Prepare: "Hang"';
    case uint16(movementTypes.WORDS_HARK)
        retVal = 'Prepare: "Hark"';
    case uint16(movementTypes.WORDS_HEAL)
        retVal = 'Prepare: "Heal"';
    case uint16(movementTypes.WORDS_HEAR)
        retVal = 'Prepare: "Hear"';
    case uint16(movementTypes.WORDS_HEAT)
        retVal = 'Prepare: "Heat"';
    case uint16(movementTypes.WORDS_HEATH)
        retVal = 'Prepare: "Heath"';
    case uint16(movementTypes.WORDS_HEAVE)
        retVal = 'Prepare: "Heave"';
    case uint16(movementTypes.WORDS_HIT)
        retVal = 'Prepare: "Hit"';
    case uint16(movementTypes.WORDS_HOLE)
        retVal = 'Prepare: "Hole"';
    case uint16(movementTypes.WORDS_HONE)
        retVal = 'Prepare: "Hone"';
    case uint16(movementTypes.WORDS_HOOD)
        retVal = 'Prepare: "Hood"';
    case uint16(movementTypes.WORDS_HOOK)
        retVal = 'Prepare: "Hook"';
    case uint16(movementTypes.WORDS_HOOP)
        retVal = 'Prepare: "Hoop"';
    case uint16(movementTypes.WORDS_HOP)
        retVal = 'Prepare: "Hop"';
    case uint16(movementTypes.WORDS_HUN)
        retVal = 'Prepare: "Hun"';
    case uint16(movementTypes.WORDS_KING)
        retVal = 'Prepare: "King"';
    case uint16(movementTypes.WORDS_LEAVE)
        retVal = 'Prepare: "Leave"';
    case uint16(movementTypes.WORDS_LIES)
        retVal = 'Prepare: "Lies"';
    case uint16(movementTypes.WORDS_LIVE)
        retVal = 'Prepare: "Live"';
    case uint16(movementTypes.WORDS_LONG)
        retVal = 'Prepare: "Long"';
    case uint16(movementTypes.WORDS_LOVE)
        retVal = 'Prepare: "Love"';
    case uint16(movementTypes.WORDS_MASSAGE)
        retVal = 'Prepare: "Massage"';
    case uint16(movementTypes.WORDS_MATH)
        retVal = 'Prepare: "Math"';
    case uint16(movementTypes.WORDS_MEASURE)
        retVal = 'Prepare: "Measure"';
    case uint16(movementTypes.WORDS_MOVE)
        retVal = 'Prepare: "Move"';
    case uint16(movementTypes.WORDS_MUSH)
        retVal = 'Prepare: "Mush"';
    case uint16(movementTypes.WORDS_PATH)
        retVal = 'Prepare: "Path"';
    case uint16(movementTypes.WORDS_PAVE)
        retVal = 'Prepare: "Pave"';
    case uint16(movementTypes.WORDS_PAYS)
        retVal = 'Prepare: "Pays"';
    case uint16(movementTypes.WORDS_PEAS)
        retVal = 'Prepare: "Peas"';
    case uint16(movementTypes.WORDS_PERSIAN)
        retVal = 'Prepare: "Persian"';
    case uint16(movementTypes.WORDS_RANG)
        retVal = 'Prepare: "Rang"';
    case uint16(movementTypes.WORDS_RAVE)
        retVal = 'Prepare: "Rave"';
    case uint16(movementTypes.WORDS_RAZE)
        retVal = 'Prepare: "Raze"';
    case uint16(movementTypes.WORDS_RUNG)
        retVal = 'Prepare: "Rung"';
    case uint16(movementTypes.WORDS_RUSH)
        retVal = 'Prepare: "Rush"';
    case uint16(movementTypes.WORDS_SANG)
        retVal = 'Prepare: "Sang"';
    case uint16(movementTypes.WORDS_SAVE)
        retVal = 'Prepare: "Save"';
    case uint16(movementTypes.WORDS_SEIZURE)
        retVal = 'Prepare: "Seizure"';
    case uint16(movementTypes.WORDS_SHAM)
        retVal = 'Prepare: "Sham"';
    case uint16(movementTypes.WORDS_SHAVE)
        retVal = 'Prepare: "Shave"';
    case uint16(movementTypes.WORDS_SHED)
        retVal = 'Prepare: "Shed"';
    case uint16(movementTypes.WORDS_SHEEP)
        retVal = 'Prepare: "Sheep"';
    case uint16(movementTypes.WORDS_SHIP)
        retVal = 'Prepare: "Ship"';
    case uint16(movementTypes.WORDS_SHONE)
        retVal = 'Prepare: "Shone"';
    case uint16(movementTypes.WORDS_SHOOK)
        retVal = 'Prepare: "Shook"';
    case uint16(movementTypes.WORDS_SHOP)
        retVal = 'Prepare: "Shop"';
    case uint16(movementTypes.WORDS_SHOVE)
        retVal = 'Prepare: "Shove"';
    case uint16(movementTypes.WORDS_SHOWS)
        retVal = 'Prepare: "Shows"';
    case uint16(movementTypes.WORDS_SING)
        retVal = 'Prepare: "Sing"';
    case uint16(movementTypes.WORDS_SUNG)
        retVal = 'Prepare: "Sung"';
    case uint16(movementTypes.WORDS_TEASE)
        retVal = 'Prepare: "Tease"';
    case uint16(movementTypes.WORDS_TEETH)
        retVal = 'Prepare: "Teeth"';
    case uint16(movementTypes.WORDS_THANK)
        retVal = 'Prepare: "Thank"';
    case uint16(movementTypes.WORDS_THAW)
        retVal = 'Prepare: "Thaw"';
    case uint16(movementTypes.WORDS_THIN)
        retVal = 'Prepare: "Thin"';
    case uint16(movementTypes.WORDS_THING)
        retVal = 'Prepare: "Thing"';
    case uint16(movementTypes.WORDS_THONG)
        retVal = 'Prepare: "Thong"';
    case uint16(movementTypes.WORDS_TOOTH)
        retVal = 'Prepare: "Tooth"';
    case uint16(movementTypes.WORDS_TURF)
        retVal = 'Prepare: "Turf"';
    case uint16(movementTypes.WORDS_USUAL)
        retVal = 'Prepare: "Usual"';
    case uint16(movementTypes.WORDS_VAN)
        retVal = 'Prepare: "Van"';
    case uint16(movementTypes.WORDS_VEIL)
        retVal = 'Prepare: "Veil"';
    case uint16(movementTypes.WORDS_VERSION)
        retVal = 'Prepare: "Version"';
    case uint16(movementTypes.WORDS_VEST)
        retVal = 'Prepare: "Vest"';
    case uint16(movementTypes.WORDS_VET)
        retVal = 'Prepare: "Vet"';
    case uint16(movementTypes.WORDS_VICE)
        retVal = 'Prepare: "Vice"';
    case uint16(movementTypes.WORDS_VILE)
        retVal = 'Prepare: "Vile"';
    case uint16(movementTypes.WORDS_VINE)
        retVal = 'Prepare: "Vine"';
    case uint16(movementTypes.WORDS_VISION)
        retVal = 'Prepare: "Vision"';
    case uint16(movementTypes.WORDS_VOICE)
        retVal = 'Prepare: "Voice"';
    case uint16(movementTypes.WORDS_VORE)
        retVal = 'Prepare: "Vore"';
    case uint16(movementTypes.WORDS_VOTE)
        retVal = 'Prepare: "Vote"';
    case uint16(movementTypes.WORDS_VOWS)
        retVal = 'Prepare: "Vows"';
    case uint16(movementTypes.WORDS_WANE)
        retVal = 'Prepare: "Wane"';
    case uint16(movementTypes.WORDS_WAS)
        retVal = 'Prepare: "Was"';
    case uint16(movementTypes.WORDS_WASH)
        retVal = 'Prepare: "Wash"';
    case uint16(movementTypes.WORDS_WAVE)
        retVal = 'Prepare: "Wave"';
    case uint16(movementTypes.WORDS_WAY)
        retVal = 'Prepare: "Way"';
    case uint16(movementTypes.WORDS_WENT)
        retVal = 'Prepare: "Went"';
    case uint16(movementTypes.WORDS_WEST)
        retVal = 'Prepare: "West"';
    case uint16(movementTypes.WORDS_WICK)
        retVal = 'Prepare: "Wick"';
    case uint16(movementTypes.WORDS_WIFE)
        retVal = 'Prepare: "Wife"';
    case uint16(movementTypes.WORDS_WINE)
        retVal = 'Prepare: "Wine"';
    case uint16(movementTypes.WORDS_WING)
        retVal = 'Prepare: "Wing"';
    case uint16(movementTypes.WORDS_WISE)
        retVal = 'Prepare: "Wise"';
    case uint16(movementTypes.WORDS_WORD)
        retVal = 'Prepare: "Word"';
    case uint16(movementTypes.WORDS_WORSE)
        retVal = 'Prepare: "Worse"';
    case uint16(movementTypes.WORDS_WRONG)
        retVal = 'Prepare: "Wrong"';
    case uint16(movementTypes.WORDS_YAM)
        retVal = 'Prepare: "Yam"';
    case uint16(movementTypes.WORDS_YAWN)
        retVal = 'Prepare: "Yawn"';
    case uint16(movementTypes.WORDS_YELL)
        retVal = 'Prepare: "Yell"';
    case uint16(movementTypes.WORDS_YEN)
        retVal = 'Prepare: "Yen"';
    case uint16(movementTypes.WORDS_YEP)
        retVal = 'Prepare: "Yep"';
    case uint16(movementTypes.WORDS_YES)
        retVal = 'Prepare: "Yes"';
    case uint16(movementTypes.WORDS_YIKES)
        retVal = 'Prepare: "Yikes"';
    case uint16(movementTypes.WORDS_YOKE)
        retVal = 'Prepare: "Yoke"';
    case uint16(movementTypes.WORDS_YON)
        retVal = 'Prepare: "Yon"';
    case uint16(movementTypes.WORDS_YOU)
        retVal = 'Prepare: "You"';
    case uint16(movementTypes.WORDS_YOUNG)
        retVal = 'Prepare: "Young"';
    case uint16(movementTypes.WORDS_YOUTH)
        retVal = 'Prepare: "Youth"';
    case uint16(movementTypes.WORDS_YUCK)
        retVal = 'Prepare: "Yuck"';
    case uint16(movementTypes.WORDS_YULE)
        retVal = 'Prepare: "Yule"';
    case uint16(movementTypes.WORDS_ZAG)
        retVal = 'Prepare: "Zag"';
    case uint16(movementTypes.WORDS_ZAP)
        retVal = 'Prepare: "Zap"';
    case uint16(movementTypes.WORDS_ZIP)
        retVal = 'Prepare: "Zip"';
    
    % SET 4
    case uint16(movementTypes.WORDS_BATHE)
        retVal = 'Prepare: "Bathe"';
    case uint16(movementTypes.WORDS_BEACH)
        retVal = 'Prepare: "Beach"';
    case uint16(movementTypes.WORDS_BIRD)
        retVal = 'Prepare: "Bird"';
    case uint16(movementTypes.WORDS_BLUE)
        retVal = 'Prepare: "Blue"';
    case uint16(movementTypes.WORDS_CAGE)
        retVal = 'Prepare: "Cage"';
    case uint16(movementTypes.WORDS_CHANGE)
        retVal = 'Prepare: "Change"';
    case uint16(movementTypes.WORDS_CHAT)
        retVal = 'Prepare: "Chat"';
    case uint16(movementTypes.WORDS_CHIN)
        retVal = 'Prepare: "Chin"';
    case uint16(movementTypes.WORDS_CHIP)
        retVal = 'Prepare: "Chip"';
    case uint16(movementTypes.WORDS_CHOICE)
        retVal = 'Prepare: "Choice"';
    case uint16(movementTypes.WORDS_CHOOSE)
        retVal = 'Prepare: "Choose"';
    case uint16(movementTypes.WORDS_CHOSE)
        retVal = 'Prepare: "Chose"';
    case uint16(movementTypes.WORDS_CHOW)
        retVal = 'Prepare: "Chow"';
    case uint16(movementTypes.WORDS_DUTCH)
        retVal = 'Prepare: "Dutch"';
    case uint16(movementTypes.WORDS_FIGHT)
        retVal = 'Prepare: "Fight"';
    case uint16(movementTypes.WORDS_FLEW)
        retVal = 'Prepare: "Flew"';
    case uint16(movementTypes.WORDS_FOOL)
        retVal = 'Prepare: "Fool"';
    case uint16(movementTypes.WORDS_GAGE)
        retVal = 'Prepare: "Gage"';
    case uint16(movementTypes.WORDS_GEL)
        retVal = 'Prepare: "Gel"';
    case uint16(movementTypes.WORDS_GEM)
        retVal = 'Prepare: "Gem"';
    case uint16(movementTypes.WORDS_GOUGE)
        retVal = 'Prepare: "Gouge"';
    case uint16(movementTypes.WORDS_HITCH)
        retVal = 'Prepare: "Hitch"';
    case uint16(movementTypes.WORDS_HUGE)
        retVal = 'Prepare: "Huge"';
    case uint16(movementTypes.WORDS_HURL)
        retVal = 'Prepare: "Hurl"';
    case uint16(movementTypes.WORDS_JAB)
        retVal = 'Prepare: "Jab"';
    case uint16(movementTypes.WORDS_JAM)
        retVal = 'Prepare: "Jam"';
    case uint16(movementTypes.WORDS_JAW)
        retVal = 'Prepare: "Jaw"';
    case uint16(movementTypes.WORDS_JAZZ)
        retVal = 'Prepare: "Jazz"';
    case uint16(movementTypes.WORDS_JIVE)
        retVal = 'Prepare: "Jive"';
    case uint16(movementTypes.WORDS_JOB)
        retVal = 'Prepare: "Job"';
    case uint16(movementTypes.WORDS_JOKE)
        retVal = 'Prepare: "Joke"';
    case uint16(movementTypes.WORDS_JOSH)
        retVal = 'Prepare: "Josh"';
    case uint16(movementTypes.WORDS_JUST)
        retVal = 'Prepare: "Just"';
    case uint16(movementTypes.WORDS_LIGHT)
        retVal = 'Prepare: "Light"';
    case uint16(movementTypes.WORDS_LOATHE)
        retVal = 'Prepare: "Loathe"';
    case uint16(movementTypes.WORDS_LUGE)
        retVal = 'Prepare: "Luge"';
    case uint16(movementTypes.WORDS_MATCH)
        retVal = 'Prepare: "Match"';
    case uint16(movementTypes.WORDS_MIGHT)
        retVal = 'Prepare: "Might"';
    case uint16(movementTypes.WORDS_MUCH)
        retVal = 'Prepare: "Much"';
    case uint16(movementTypes.WORDS_PAGE)
        retVal = 'Prepare: "Page"';
    case uint16(movementTypes.WORDS_PEACH)
        retVal = 'Prepare: "Peach"';
    case uint16(movementTypes.WORDS_PITCH)
        retVal = 'Prepare: "Pitch"';
    case uint16(movementTypes.WORDS_RAGE)
        retVal = 'Prepare: "Rage"';
    case uint16(movementTypes.WORDS_REACH)
        retVal = 'Prepare: "Reach"';
    case uint16(movementTypes.WORDS_RIDE)
        retVal = 'Prepare: "Ride"';
    case uint16(movementTypes.WORDS_ROOF)
        retVal = 'Prepare: "Roof"';
    case uint16(movementTypes.WORDS_SAGE)
        retVal = 'Prepare: "Sage"';
    case uint16(movementTypes.WORDS_SEETHE)
        retVal = 'Prepare: "Seethe"';
    case uint16(movementTypes.WORDS_TEACH)
        retVal = 'Prepare: "Teach"';
    case uint16(movementTypes.WORDS_TEETHE)
        retVal = 'Prepare: "Teethe"';
    case uint16(movementTypes.WORDS_THAN)
        retVal = 'Prepare: "Than"';
    case uint16(movementTypes.WORDS_THAT)
        retVal = 'Prepare: "That"';
    case uint16(movementTypes.WORDS_THATCH)
        retVal = 'Prepare: "Thatch"';
    case uint16(movementTypes.WORDS_THEE)
        retVal = 'Prepare: "Thee"';
    case uint16(movementTypes.WORDS_THEM)
        retVal = 'Prepare: "Them"';
    case uint16(movementTypes.WORDS_THEN)
        retVal = 'Prepare: "Then"';
    case uint16(movementTypes.WORDS_THERE)
        retVal = 'Prepare: "There"';
    case uint16(movementTypes.WORDS_THEY)
        retVal = 'Prepare: "They"';
    case uint16(movementTypes.WORDS_THIS)
        retVal = 'Prepare: "This"';
    case uint16(movementTypes.WORDS_THOSE)
        retVal = 'Prepare: "Those"';
    case uint16(movementTypes.WORDS_THOUGH)
        retVal = 'Prepare: "Though"';
    case uint16(movementTypes.WORDS_TITHE)
        retVal = 'Prepare: "Tithe"';
    case uint16(movementTypes.WORDS_TRUE)
        retVal = 'Prepare: "True"';
    case uint16(movementTypes.WORDS_WATCH)
        retVal = 'Prepare: "Watch"';
    case uint16(movementTypes.WORDS_MORE)
        retVal = 'Prepare: "More"';
    case uint16(movementTypes.WORDS_SEAL)
        retVal = 'Prepare: "Seal"';    
    case uint16(movementTypes.WORDS_SHOT)
        retVal = 'Prepare: "Shot"';        
        
    %FRW 1000 most frequent english words (Paul Nation; derived from BNC/COCA), in a shuffled order
    case uint16(movementTypes.HANDWORDS_HURT)
        retVal = 'Prepare: hurt';
    case uint16(movementTypes.HANDWORDS_EMPLOY)
        retVal = 'Prepare: employ';
    case uint16(movementTypes.HANDWORDS_PENNY)
        retVal = 'Prepare: penny';
    case uint16(movementTypes.HANDWORDS_ELSE)
        retVal = 'Prepare: else';
    case uint16(movementTypes.HANDWORDS_MUSIC)
        retVal = 'Prepare: music';
    case uint16(movementTypes.HANDWORDS_FRIDAY)
        retVal = 'Prepare: friday';
    case uint16(movementTypes.HANDWORDS_NEAR)
        retVal = 'Prepare: near';
    case uint16(movementTypes.HANDWORDS_LARGE)
        retVal = 'Prepare: large';
    case uint16(movementTypes.HANDWORDS_PROMISE)
        retVal = 'Prepare: promise';
    case uint16(movementTypes.HANDWORDS_SO)
        retVal = 'Prepare: so';
    case uint16(movementTypes.HANDWORDS_THING)
        retVal = 'Prepare: thing';
    case uint16(movementTypes.HANDWORDS_SING)
        retVal = 'Prepare: sing';
    case uint16(movementTypes.HANDWORDS_GAS)
        retVal = 'Prepare: gas';
    case uint16(movementTypes.HANDWORDS_VISIT)
        retVal = 'Prepare: visit';
    case uint16(movementTypes.HANDWORDS_TREAT)
        retVal = 'Prepare: treat';
    case uint16(movementTypes.HANDWORDS_LUCK)
        retVal = 'Prepare: luck';
    case uint16(movementTypes.HANDWORDS_AWARE)
        retVal = 'Prepare: aware';
    case uint16(movementTypes.HANDWORDS_ROLL)
        retVal = 'Prepare: roll';
    case uint16(movementTypes.HANDWORDS_OWNED)
        retVal = 'Prepare: owned';
    case uint16(movementTypes.HANDWORDS_POT)
        retVal = 'Prepare: pot';
    case uint16(movementTypes.HANDWORDS_BURN)
        retVal = 'Prepare: burn';
    case uint16(movementTypes.HANDWORDS_NORMAL)
        retVal = 'Prepare: normal';
    case uint16(movementTypes.HANDWORDS_SIGHT)
        retVal = 'Prepare: sight';
    case uint16(movementTypes.HANDWORDS_SHOULDER)
        retVal = 'Prepare: shoulder';
    case uint16(movementTypes.HANDWORDS_TEAM)
        retVal = 'Prepare: team';
    case uint16(movementTypes.HANDWORDS_HAIR)
        retVal = 'Prepare: hair';
    case uint16(movementTypes.HANDWORDS_ON)
        retVal = 'Prepare: on';
    case uint16(movementTypes.HANDWORDS_WITHIN)
        retVal = 'Prepare: within';
    case uint16(movementTypes.HANDWORDS_LIVE)
        retVal = 'Prepare: live';
    case uint16(movementTypes.HANDWORDS_UNDER)
        retVal = 'Prepare: under';
    case uint16(movementTypes.HANDWORDS_DOG)
        retVal = 'Prepare: dog';
    case uint16(movementTypes.HANDWORDS_GRANDFATHER)
        retVal = 'Prepare: grandfather';
    case uint16(movementTypes.HANDWORDS_BED)
        retVal = 'Prepare: bed';
    case uint16(movementTypes.HANDWORDS_MORNING)
        retVal = 'Prepare: morning';
    case uint16(movementTypes.HANDWORDS_THERE)
        retVal = 'Prepare: there';
    case uint16(movementTypes.HANDWORDS_FAMILY)
        retVal = 'Prepare: family';
    case uint16(movementTypes.HANDWORDS_BAG)
        retVal = 'Prepare: bag';
    case uint16(movementTypes.HANDWORDS_SINGLE)
        retVal = 'Prepare: single';
    case uint16(movementTypes.HANDWORDS_EXPERIENCE)
        retVal = 'Prepare: experience';
    case uint16(movementTypes.HANDWORDS_MILE)
        retVal = 'Prepare: mile';
    case uint16(movementTypes.HANDWORDS_CLOSE)
        retVal = 'Prepare: close';
    case uint16(movementTypes.HANDWORDS_HOWEVER)
        retVal = 'Prepare: however';
    case uint16(movementTypes.HANDWORDS_GOODBYE)
        retVal = 'Prepare: goodbye';
    case uint16(movementTypes.HANDWORDS_CUT)
        retVal = 'Prepare: cut';
    case uint16(movementTypes.HANDWORDS_EXPENSIVE)
        retVal = 'Prepare: expensive';
    case uint16(movementTypes.HANDWORDS_COLLECT)
        retVal = 'Prepare: collect';
    case uint16(movementTypes.HANDWORDS_BIT)
        retVal = 'Prepare: bit';
    case uint16(movementTypes.HANDWORDS_FOOTBALL)
        retVal = 'Prepare: football';
    case uint16(movementTypes.HANDWORDS_FAST)
        retVal = 'Prepare: fast';
    case uint16(movementTypes.HANDWORDS_SURE)
        retVal = 'Prepare: sure';
    case uint16(movementTypes.HANDWORDS_COULD)
        retVal = 'Prepare: could';
    case uint16(movementTypes.HANDWORDS_INTO)
        retVal = 'Prepare: into';
    case uint16(movementTypes.HANDWORDS_COMFORT)
        retVal = 'Prepare: comfort';
    case uint16(movementTypes.HANDWORDS_WEB)
        retVal = 'Prepare: web';
    case uint16(movementTypes.HANDWORDS_KITCHEN)
        retVal = 'Prepare: kitchen';
    case uint16(movementTypes.HANDWORDS_ADDRESS)
        retVal = 'Prepare: address';
    case uint16(movementTypes.HANDWORDS_DEPEND)
        retVal = 'Prepare: depend';
    case uint16(movementTypes.HANDWORDS_NICE)
        retVal = 'Prepare: nice';
    case uint16(movementTypes.HANDWORDS_THIS)
        retVal = 'Prepare: this';
    case uint16(movementTypes.HANDWORDS_MORE)
        retVal = 'Prepare: more';
    case uint16(movementTypes.HANDWORDS_AGO)
        retVal = 'Prepare: ago';
    case uint16(movementTypes.HANDWORDS_LOW)
        retVal = 'Prepare: low';
    case uint16(movementTypes.HANDWORDS_FULL)
        retVal = 'Prepare: full';
    case uint16(movementTypes.HANDWORDS_OFTEN)
        retVal = 'Prepare: often';
    case uint16(movementTypes.HANDWORDS_SUMMER)
        retVal = 'Prepare: summer';
    case uint16(movementTypes.HANDWORDS_TERM)
        retVal = 'Prepare: term';
    case uint16(movementTypes.HANDWORDS_THROUGH)
        retVal = 'Prepare: through';
    case uint16(movementTypes.HANDWORDS_LITTLE)
        retVal = 'Prepare: little';
    case uint16(movementTypes.HANDWORDS_MARKET)
        retVal = 'Prepare: market';
    case uint16(movementTypes.HANDWORDS_WELL)
        retVal = 'Prepare: well';
    case uint16(movementTypes.HANDWORDS_PLAY)
        retVal = 'Prepare: play';
    case uint16(movementTypes.HANDWORDS_REALLY)
        retVal = 'Prepare: really';
    case uint16(movementTypes.HANDWORDS_EXPRESS)
        retVal = 'Prepare: express';
    case uint16(movementTypes.HANDWORDS_PROPER)
        retVal = 'Prepare: proper';
    case uint16(movementTypes.HANDWORDS_MISTER)
        retVal = 'Prepare: mister';
    case uint16(movementTypes.HANDWORDS_WIFE)
        retVal = 'Prepare: wife';
    case uint16(movementTypes.HANDWORDS_INTERNET)
        retVal = 'Prepare: internet';
    case uint16(movementTypes.HANDWORDS_LEFT)
        retVal = 'Prepare: left';
    case uint16(movementTypes.HANDWORDS_SEVEN)
        retVal = 'Prepare: seven';
    case uint16(movementTypes.HANDWORDS_WHILE)
        retVal = 'Prepare: while';
    case uint16(movementTypes.HANDWORDS_SHOE)
        retVal = 'Prepare: shoe';
    case uint16(movementTypes.HANDWORDS_ANGRY)
        retVal = 'Prepare: angry';
    case uint16(movementTypes.HANDWORDS_PERHAPS)
        retVal = 'Prepare: perhaps';
    case uint16(movementTypes.HANDWORDS_ISLAND)
        retVal = 'Prepare: island';
    case uint16(movementTypes.HANDWORDS_RENT)
        retVal = 'Prepare: rent';
    case uint16(movementTypes.HANDWORDS_MENTION)
        retVal = 'Prepare: mention';
    case uint16(movementTypes.HANDWORDS_EMPTY)
        retVal = 'Prepare: empty';
    case uint16(movementTypes.HANDWORDS_SYSTEM)
        retVal = 'Prepare: system';
    case uint16(movementTypes.HANDWORDS_HILL)
        retVal = 'Prepare: hill';
    case uint16(movementTypes.HANDWORDS_MOUNTAIN)
        retVal = 'Prepare: mountain';
    case uint16(movementTypes.HANDWORDS_ANSWER)
        retVal = 'Prepare: answer';
    case uint16(movementTypes.HANDWORDS_TAKE)
        retVal = 'Prepare: take';
    case uint16(movementTypes.HANDWORDS_CLEAR)
        retVal = 'Prepare: clear';
    case uint16(movementTypes.HANDWORDS_FIX)
        retVal = 'Prepare: fix';
    case uint16(movementTypes.HANDWORDS_SIGN)
        retVal = 'Prepare: sign';
    case uint16(movementTypes.HANDWORDS_IMPORTANT)
        retVal = 'Prepare: important';
    case uint16(movementTypes.HANDWORDS_SUCH)
        retVal = 'Prepare: such';
    case uint16(movementTypes.HANDWORDS_SUPPOSE)
        retVal = 'Prepare: suppose';
    case uint16(movementTypes.HANDWORDS_TERRIBLE)
        retVal = 'Prepare: terrible';
    case uint16(movementTypes.HANDWORDS_TRIP)
        retVal = 'Prepare: trip';
    case uint16(movementTypes.HANDWORDS_SEA)
        retVal = 'Prepare: sea';
    case uint16(movementTypes.HANDWORDS_NEWS)
        retVal = 'Prepare: news';
    case uint16(movementTypes.HANDWORDS_SLOW)
        retVal = 'Prepare: slow';
    case uint16(movementTypes.HANDWORDS_ACTUAL)
        retVal = 'Prepare: actual';
    case uint16(movementTypes.HANDWORDS_SPORT)
        retVal = 'Prepare: sport';
    case uint16(movementTypes.HANDWORDS_OPEN)
        retVal = 'Prepare: open';
    case uint16(movementTypes.HANDWORDS_BORING)
        retVal = 'Prepare: boring';
    case uint16(movementTypes.HANDWORDS_PART)
        retVal = 'Prepare: part';
    case uint16(movementTypes.HANDWORDS_COLD)
        retVal = 'Prepare: cold';
    case uint16(movementTypes.HANDWORDS_LET)
        retVal = 'Prepare: let';
    case uint16(movementTypes.HANDWORDS_BLUE)
        retVal = 'Prepare: blue';
    case uint16(movementTypes.HANDWORDS_HONEST)
        retVal = 'Prepare: honest';
    case uint16(movementTypes.HANDWORDS_RIDE)
        retVal = 'Prepare: ride';
    case uint16(movementTypes.HANDWORDS_LAZY)
        retVal = 'Prepare: lazy';
    case uint16(movementTypes.HANDWORDS_BEGIN)
        retVal = 'Prepare: begin';
    case uint16(movementTypes.HANDWORDS_A)
        retVal = 'Prepare: a';
    case uint16(movementTypes.HANDWORDS_BEHIND)
        retVal = 'Prepare: behind';
    case uint16(movementTypes.HANDWORDS_AFFORD)
        retVal = 'Prepare: afford';
    case uint16(movementTypes.HANDWORDS_HUGE)
        retVal = 'Prepare: huge';
    case uint16(movementTypes.HANDWORDS_NINE)
        retVal = 'Prepare: nine';
    case uint16(movementTypes.HANDWORDS_MAJOR)
        retVal = 'Prepare: major';
    case uint16(movementTypes.HANDWORDS_SEX)
        retVal = 'Prepare: sex';
    case uint16(movementTypes.HANDWORDS_HUNGER)
        retVal = 'Prepare: hunger';
    case uint16(movementTypes.HANDWORDS_BOTTLE)
        retVal = 'Prepare: bottle';
    case uint16(movementTypes.HANDWORDS_FLY)
        retVal = 'Prepare: fly';
    case uint16(movementTypes.HANDWORDS_ALTHOUGH)
        retVal = 'Prepare: although';
    case uint16(movementTypes.HANDWORDS_ICE)
        retVal = 'Prepare: ice';
    case uint16(movementTypes.HANDWORDS_STRIKE)
        retVal = 'Prepare: strike';
    case uint16(movementTypes.HANDWORDS_AS)
        retVal = 'Prepare: as';
    case uint16(movementTypes.HANDWORDS_NATION)
        retVal = 'Prepare: nation';
    case uint16(movementTypes.HANDWORDS_BLOOD)
        retVal = 'Prepare: blood';
    case uint16(movementTypes.HANDWORDS_CUP)
        retVal = 'Prepare: cup';
    case uint16(movementTypes.HANDWORDS_TRUTH)
        retVal = 'Prepare: truth';
    case uint16(movementTypes.HANDWORDS_CHANCE)
        retVal = 'Prepare: chance';
    case uint16(movementTypes.HANDWORDS_LAUGH)
        retVal = 'Prepare: laugh';
    case uint16(movementTypes.HANDWORDS_GIRL)
        retVal = 'Prepare: girl';
    case uint16(movementTypes.HANDWORDS_SERVE)
        retVal = 'Prepare: serve';
    case uint16(movementTypes.HANDWORDS_FORGET)
        retVal = 'Prepare: forget';
    case uint16(movementTypes.HANDWORDS_CRY)
        retVal = 'Prepare: cry';
    case uint16(movementTypes.HANDWORDS_EAT)
        retVal = 'Prepare: eat';
    case uint16(movementTypes.HANDWORDS_MARRY)
        retVal = 'Prepare: marry';
    case uint16(movementTypes.HANDWORDS_HOUR)
        retVal = 'Prepare: hour';
    case uint16(movementTypes.HANDWORDS_BROWN)
        retVal = 'Prepare: brown';
    case uint16(movementTypes.HANDWORDS_SUN)
        retVal = 'Prepare: sun';
    case uint16(movementTypes.HANDWORDS_BEACH)
        retVal = 'Prepare: beach';
    case uint16(movementTypes.HANDWORDS_EXCEPT)
        retVal = 'Prepare: except';
    case uint16(movementTypes.HANDWORDS_STREET)
        retVal = 'Prepare: street';
    case uint16(movementTypes.HANDWORDS_THANK)
        retVal = 'Prepare: thank';
    case uint16(movementTypes.HANDWORDS_WORD)
        retVal = 'Prepare: word';
    case uint16(movementTypes.HANDWORDS_ALLOW)
        retVal = 'Prepare: allow';
    case uint16(movementTypes.HANDWORDS_BOY)
        retVal = 'Prepare: boy';
    case uint16(movementTypes.HANDWORDS_FEEL)
        retVal = 'Prepare: feel';
    case uint16(movementTypes.HANDWORDS_ABOVE)
        retVal = 'Prepare: above';
    case uint16(movementTypes.HANDWORDS_OFF)
        retVal = 'Prepare: off';
    case uint16(movementTypes.HANDWORDS_STAY)
        retVal = 'Prepare: stay';
    case uint16(movementTypes.HANDWORDS_MEMBER)
        retVal = 'Prepare: member';
    case uint16(movementTypes.HANDWORDS_QUICK)
        retVal = 'Prepare: quick';
    case uint16(movementTypes.HANDWORDS_DRINK)
        retVal = 'Prepare: drink';
    case uint16(movementTypes.HANDWORDS_QUARTER)
        retVal = 'Prepare: quarter';
    case uint16(movementTypes.HANDWORDS_SHOP)
        retVal = 'Prepare: shop';
    case uint16(movementTypes.HANDWORDS_THOUSAND)
        retVal = 'Prepare: thousand';
    case uint16(movementTypes.HANDWORDS_QUEEN)
        retVal = 'Prepare: queen';
    case uint16(movementTypes.HANDWORDS_GREAT)
        retVal = 'Prepare: great';
    case uint16(movementTypes.HANDWORDS_JOKE)
        retVal = 'Prepare: joke';
    case uint16(movementTypes.HANDWORDS_RADIO)
        retVal = 'Prepare: radio';
    case uint16(movementTypes.HANDWORDS_EXCITE)
        retVal = 'Prepare: excite';
    case uint16(movementTypes.HANDWORDS_FACE)
        retVal = 'Prepare: face';
    case uint16(movementTypes.HANDWORDS_CHOICE)
        retVal = 'Prepare: choice';
    case uint16(movementTypes.HANDWORDS_AMAZE)
        retVal = 'Prepare: amaze';
    case uint16(movementTypes.HANDWORDS_CHILD)
        retVal = 'Prepare: child';
    case uint16(movementTypes.HANDWORDS_GOD)
        retVal = 'Prepare: god';
    case uint16(movementTypes.HANDWORDS_BACK)
        retVal = 'Prepare: back';
    case uint16(movementTypes.HANDWORDS_THIRTEEN)
        retVal = 'Prepare: thirteen';
    case uint16(movementTypes.HANDWORDS_AT)
        retVal = 'Prepare: at';
    case uint16(movementTypes.HANDWORDS_NOSE)
        retVal = 'Prepare: nose';
    case uint16(movementTypes.HANDWORDS_SHUT)
        retVal = 'Prepare: shut';
    case uint16(movementTypes.HANDWORDS_DIFFERENCE)
        retVal = 'Prepare: difference';
    case uint16(movementTypes.HANDWORDS_LOUD)
        retVal = 'Prepare: loud';
    case uint16(movementTypes.HANDWORDS_PRISON)
        retVal = 'Prepare: prison';
    case uint16(movementTypes.HANDWORDS_ACROSS)
        retVal = 'Prepare: across';
    case uint16(movementTypes.HANDWORDS_WALK)
        retVal = 'Prepare: walk';
    case uint16(movementTypes.HANDWORDS_EDGE)
        retVal = 'Prepare: edge';
    case uint16(movementTypes.HANDWORDS_WEDNESDAY)
        retVal = 'Prepare: wednesday';
    case uint16(movementTypes.HANDWORDS_TIGHT)
        retVal = 'Prepare: tight';
    case uint16(movementTypes.HANDWORDS_FIGHT)
        retVal = 'Prepare: fight';
    case uint16(movementTypes.HANDWORDS_RECORD)
        retVal = 'Prepare: record';
    case uint16(movementTypes.HANDWORDS_HOLD)
        retVal = 'Prepare: hold';
    case uint16(movementTypes.HANDWORDS_STUFF)
        retVal = 'Prepare: stuff';
    case uint16(movementTypes.HANDWORDS_RUBBISH)
        retVal = 'Prepare: rubbish';
    case uint16(movementTypes.HANDWORDS_BETTER)
        retVal = 'Prepare: better';
    case uint16(movementTypes.HANDWORDS_DIE)
        retVal = 'Prepare: die';
    case uint16(movementTypes.HANDWORDS_CHIP)
        retVal = 'Prepare: chip';
    case uint16(movementTypes.HANDWORDS_FIT)
        retVal = 'Prepare: fit';
    case uint16(movementTypes.HANDWORDS_BOARD)
        retVal = 'Prepare: board';
    case uint16(movementTypes.HANDWORDS_NOTE)
        retVal = 'Prepare: note';
    case uint16(movementTypes.HANDWORDS_SIT)
        retVal = 'Prepare: sit';
    case uint16(movementTypes.HANDWORDS_TYPE)
        retVal = 'Prepare: type';
    case uint16(movementTypes.HANDWORDS_TOO)
        retVal = 'Prepare: too';
    case uint16(movementTypes.HANDWORDS_REASON)
        retVal = 'Prepare: reason';
    case uint16(movementTypes.HANDWORDS_LISTEN)
        retVal = 'Prepare: listen';
    case uint16(movementTypes.HANDWORDS_LEVEL)
        retVal = 'Prepare: level';
    case uint16(movementTypes.HANDWORDS_HEART)
        retVal = 'Prepare: heart';
    case uint16(movementTypes.HANDWORDS_GREEN)
        retVal = 'Prepare: green';
    case uint16(movementTypes.HANDWORDS_PAGE)
        retVal = 'Prepare: page';
    case uint16(movementTypes.HANDWORDS_OWN)
        retVal = 'Prepare: own';
    case uint16(movementTypes.HANDWORDS_GREY)
        retVal = 'Prepare: grey';
    case uint16(movementTypes.HANDWORDS_DOWN)
        retVal = 'Prepare: down';
    case uint16(movementTypes.HANDWORDS_LOVELY)
        retVal = 'Prepare: lovely';
    case uint16(movementTypes.HANDWORDS_LORD)
        retVal = 'Prepare: lord';
    case uint16(movementTypes.HANDWORDS_AUTUMN)
        retVal = 'Prepare: autumn';
    case uint16(movementTypes.HANDWORDS_CLUB)
        retVal = 'Prepare: club';
    case uint16(movementTypes.HANDWORDS_DOCTOR)
        retVal = 'Prepare: doctor';
    case uint16(movementTypes.HANDWORDS_SAIL)
        retVal = 'Prepare: sail';
    case uint16(movementTypes.HANDWORDS_WHAT)
        retVal = 'Prepare: what';
    case uint16(movementTypes.HANDWORDS_ENOUGH)
        retVal = 'Prepare: enough';
    case uint16(movementTypes.HANDWORDS_QUIET)
        retVal = 'Prepare: quiet';
    case uint16(movementTypes.HANDWORDS_ELEVEN)
        retVal = 'Prepare: eleven';
    case uint16(movementTypes.HANDWORDS_THAN)
        retVal = 'Prepare: than';
    case uint16(movementTypes.HANDWORDS_HARD)
        retVal = 'Prepare: hard';
    case uint16(movementTypes.HANDWORDS_STATE)
        retVal = 'Prepare: state';
    case uint16(movementTypes.HANDWORDS_NOBODY)
        retVal = 'Prepare: nobody';
    case uint16(movementTypes.HANDWORDS_TIRE)
        retVal = 'Prepare: tire';
    case uint16(movementTypes.HANDWORDS_HOW)
        retVal = 'Prepare: how';
    case uint16(movementTypes.HANDWORDS_OFFICER)
        retVal = 'Prepare: officer';
    case uint16(movementTypes.HANDWORDS_POLICE)
        retVal = 'Prepare: police';
    case uint16(movementTypes.HANDWORDS_DROP)
        retVal = 'Prepare: drop';
    case uint16(movementTypes.HANDWORDS_KID)
        retVal = 'Prepare: kid';
    case uint16(movementTypes.HANDWORDS_DARLING)
        retVal = 'Prepare: darling';
    case uint16(movementTypes.HANDWORDS_MAYBE)
        retVal = 'Prepare: maybe';
    case uint16(movementTypes.HANDWORDS_OUGHT)
        retVal = 'Prepare: ought';
    case uint16(movementTypes.HANDWORDS_MACHINE)
        retVal = 'Prepare: machine';
    case uint16(movementTypes.HANDWORDS_FOOT)
        retVal = 'Prepare: foot';
    case uint16(movementTypes.HANDWORDS_FILL)
        retVal = 'Prepare: fill';
    case uint16(movementTypes.HANDWORDS_AIR)
        retVal = 'Prepare: air';
    case uint16(movementTypes.HANDWORDS_HELLO)
        retVal = 'Prepare: hello';
    case uint16(movementTypes.HANDWORDS_NO)
        retVal = 'Prepare: no';
    case uint16(movementTypes.HANDWORDS_MISTAKE)
        retVal = 'Prepare: mistake';
    case uint16(movementTypes.HANDWORDS_ABSOLUTE)
        retVal = 'Prepare: absolute';
    case uint16(movementTypes.HANDWORDS_FLOOR)
        retVal = 'Prepare: floor';
    case uint16(movementTypes.HANDWORDS_LADY)
        retVal = 'Prepare: lady';
    case uint16(movementTypes.HANDWORDS_COFFEE)
        retVal = 'Prepare: coffee';
    case uint16(movementTypes.HANDWORDS_HOUSE)
        retVal = 'Prepare: house';
    case uint16(movementTypes.HANDWORDS_HEAR)
        retVal = 'Prepare: hear';
    case uint16(movementTypes.HANDWORDS_FUN)
        retVal = 'Prepare: fun';
    case uint16(movementTypes.HANDWORDS_TEAR)
        retVal = 'Prepare: tear';
    case uint16(movementTypes.HANDWORDS_CONVERSATION)
        retVal = 'Prepare: conversation';
    case uint16(movementTypes.HANDWORDS_HOPE)
        retVal = 'Prepare: hope';
    case uint16(movementTypes.HANDWORDS_KEY)
        retVal = 'Prepare: key';
    case uint16(movementTypes.HANDWORDS_GARDEN)
        retVal = 'Prepare: garden';
    case uint16(movementTypes.HANDWORDS_MEET)
        retVal = 'Prepare: meet';
    case uint16(movementTypes.HANDWORDS_WIND)
        retVal = 'Prepare: wind';
    case uint16(movementTypes.HANDWORDS_WINE)
        retVal = 'Prepare: wine';
    case uint16(movementTypes.HANDWORDS_TEN)
        retVal = 'Prepare: ten';
    case uint16(movementTypes.HANDWORDS_NEVER)
        retVal = 'Prepare: never';
    case uint16(movementTypes.HANDWORDS_WAR)
        retVal = 'Prepare: war';
    case uint16(movementTypes.HANDWORDS_MAN)
        retVal = 'Prepare: man';
    case uint16(movementTypes.HANDWORDS_DECIDE)
        retVal = 'Prepare: decide';
    case uint16(movementTypes.HANDWORDS_LOOK)
        retVal = 'Prepare: look';
    case uint16(movementTypes.HANDWORDS_BE)
        retVal = 'Prepare: be';
    case uint16(movementTypes.HANDWORDS_INDEED)
        retVal = 'Prepare: indeed';
    case uint16(movementTypes.HANDWORDS_TELL)
        retVal = 'Prepare: tell';
    case uint16(movementTypes.HANDWORDS_IDEA)
        retVal = 'Prepare: idea';
    case uint16(movementTypes.HANDWORDS_STEP)
        retVal = 'Prepare: step';
    case uint16(movementTypes.HANDWORDS_EIGHT)
        retVal = 'Prepare: eight';
    case uint16(movementTypes.HANDWORDS_IF)
        retVal = 'Prepare: if';
    case uint16(movementTypes.HANDWORDS_WHERE)
        retVal = 'Prepare: where';
    case uint16(movementTypes.HANDWORDS_CORNER)
        retVal = 'Prepare: corner';
    case uint16(movementTypes.HANDWORDS_UNTIL)
        retVal = 'Prepare: until';
    case uint16(movementTypes.HANDWORDS_WAVE)
        retVal = 'Prepare: wave';
    case uint16(movementTypes.HANDWORDS_SOME)
        retVal = 'Prepare: some';
    case uint16(movementTypes.HANDWORDS_FARM)
        retVal = 'Prepare: farm';
    case uint16(movementTypes.HANDWORDS_SET)
        retVal = 'Prepare: set';
    case uint16(movementTypes.HANDWORDS_STOP)
        retVal = 'Prepare: stop';
    case uint16(movementTypes.HANDWORDS_MEAL)
        retVal = 'Prepare: meal';
    case uint16(movementTypes.HANDWORDS_COURSE)
        retVal = 'Prepare: course';
    case uint16(movementTypes.HANDWORDS_LESS)
        retVal = 'Prepare: less';
    case uint16(movementTypes.HANDWORDS_EARLY)
        retVal = 'Prepare: early';
    case uint16(movementTypes.HANDWORDS_ONCE)
        retVal = 'Prepare: once';
    case uint16(movementTypes.HANDWORDS_OUT)
        retVal = 'Prepare: out';
    case uint16(movementTypes.HANDWORDS_CHICKEN)
        retVal = 'Prepare: chicken';
    case uint16(movementTypes.HANDWORDS_DATE)
        retVal = 'Prepare: date';
    case uint16(movementTypes.HANDWORDS_TILL)
        retVal = 'Prepare: till';
    case uint16(movementTypes.HANDWORDS_MOMENT)
        retVal = 'Prepare: moment';
    case uint16(movementTypes.HANDWORDS_WASTE)
        retVal = 'Prepare: waste';
    case uint16(movementTypes.HANDWORDS_AMOUNT)
        retVal = 'Prepare: amount';
    case uint16(movementTypes.HANDWORDS_THOUGH)
        retVal = 'Prepare: though';
    case uint16(movementTypes.HANDWORDS_GLAD)
        retVal = 'Prepare: glad';
    case uint16(movementTypes.HANDWORDS_CHARGE)
        retVal = 'Prepare: charge';
    case uint16(movementTypes.HANDWORDS_GROUP)
        retVal = 'Prepare: group';
    case uint16(movementTypes.HANDWORDS_HURRY)
        retVal = 'Prepare: hurry';
    case uint16(movementTypes.HANDWORDS_GET)
        retVal = 'Prepare: get';
    case uint16(movementTypes.HANDWORDS_MUM)
        retVal = 'Prepare: mum';
    case uint16(movementTypes.HANDWORDS_FURTHER)
        retVal = 'Prepare: further';
    case uint16(movementTypes.HANDWORDS_RELATE)
        retVal = 'Prepare: relate';
    case uint16(movementTypes.HANDWORDS_NIGHT)
        retVal = 'Prepare: night';
    case uint16(movementTypes.HANDWORDS_ONLY)
        retVal = 'Prepare: only';
    case uint16(movementTypes.HANDWORDS_APART)
        retVal = 'Prepare: apart';
    case uint16(movementTypes.HANDWORDS_EXACT)
        retVal = 'Prepare: exact';
    case uint16(movementTypes.HANDWORDS_OK)
        retVal = 'Prepare: ok';
    case uint16(movementTypes.HANDWORDS_LETTER)
        retVal = 'Prepare: letter';
    case uint16(movementTypes.HANDWORDS_SHIP)
        retVal = 'Prepare: ship';
    case uint16(movementTypes.HANDWORDS_FEAR)
        retVal = 'Prepare: fear';
    case uint16(movementTypes.HANDWORDS_THROAT)
        retVal = 'Prepare: throat';
    case uint16(movementTypes.HANDWORDS_ORANGE)
        retVal = 'Prepare: orange';
    case uint16(movementTypes.HANDWORDS_PARK)
        retVal = 'Prepare: park';
    case uint16(movementTypes.HANDWORDS_BREAKFAST)
        retVal = 'Prepare: breakfast';
    case uint16(movementTypes.HANDWORDS_CAR)
        retVal = 'Prepare: car';
    case uint16(movementTypes.HANDWORDS_COMPANY)
        retVal = 'Prepare: company';
    case uint16(movementTypes.HANDWORDS_FORM)
        retVal = 'Prepare: form';
    case uint16(movementTypes.HANDWORDS_MEAN)
        retVal = 'Prepare: mean';
    case uint16(movementTypes.HANDWORDS_CAMP)
        retVal = 'Prepare: camp';
    case uint16(movementTypes.HANDWORDS_GUN)
        retVal = 'Prepare: gun';
    case uint16(movementTypes.HANDWORDS_EXCUSE)
        retVal = 'Prepare: excuse';
    case uint16(movementTypes.HANDWORDS_LEARN)
        retVal = 'Prepare: learn';
    case uint16(movementTypes.HANDWORDS_UNCLE)
        retVal = 'Prepare: uncle';
    case uint16(movementTypes.HANDWORDS_LAKE)
        retVal = 'Prepare: lake';
    case uint16(movementTypes.HANDWORDS_TRUE)
        retVal = 'Prepare: true';
    case uint16(movementTypes.HANDWORDS_HAND)
        retVal = 'Prepare: hand';
    case uint16(movementTypes.HANDWORDS_QUITE)
        retVal = 'Prepare: quite';
    case uint16(movementTypes.HANDWORDS_LOCAL)
        retVal = 'Prepare: local';
    case uint16(movementTypes.HANDWORDS_ACT)
        retVal = 'Prepare: act';
    case uint16(movementTypes.HANDWORDS_WEATHER)
        retVal = 'Prepare: weather';
    case uint16(movementTypes.HANDWORDS_ART)
        retVal = 'Prepare: art';
    case uint16(movementTypes.HANDWORDS_NOISE)
        retVal = 'Prepare: noise';
    case uint16(movementTypes.HANDWORDS_HEALTH)
        retVal = 'Prepare: health';
    case uint16(movementTypes.HANDWORDS_MOTHER)
        retVal = 'Prepare: mother';
    case uint16(movementTypes.HANDWORDS_JUMP)
        retVal = 'Prepare: jump';
    case uint16(movementTypes.HANDWORDS_WHICH)
        retVal = 'Prepare: which';
    case uint16(movementTypes.HANDWORDS_KNOCK)
        retVal = 'Prepare: knock';
    case uint16(movementTypes.HANDWORDS_EXPECT)
        retVal = 'Prepare: expect';
    case uint16(movementTypes.HANDWORDS_SEAT)
        retVal = 'Prepare: seat';
    case uint16(movementTypes.HANDWORDS_NORTH)
        retVal = 'Prepare: north';
    case uint16(movementTypes.HANDWORDS_STRONG)
        retVal = 'Prepare: strong';
    case uint16(movementTypes.HANDWORDS_EXPLAIN)
        retVal = 'Prepare: explain';
    case uint16(movementTypes.HANDWORDS_BY)
        retVal = 'Prepare: by';
    case uint16(movementTypes.HANDWORDS_CATCH)
        retVal = 'Prepare: catch';
    case uint16(movementTypes.HANDWORDS_ALONE)
        retVal = 'Prepare: alone';
    case uint16(movementTypes.HANDWORDS_COVER)
        retVal = 'Prepare: cover';
    case uint16(movementTypes.HANDWORDS_BIRTH)
        retVal = 'Prepare: birth';
    case uint16(movementTypes.HANDWORDS_SPECIAL)
        retVal = 'Prepare: special';
    case uint16(movementTypes.HANDWORDS_MONEY)
        retVal = 'Prepare: money';
    case uint16(movementTypes.HANDWORDS_BASIC)
        retVal = 'Prepare: basic';
    case uint16(movementTypes.HANDWORDS_WARM)
        retVal = 'Prepare: warm';
    case uint16(movementTypes.HANDWORDS_CLOTHES)
        retVal = 'Prepare: clothes';
    case uint16(movementTypes.HANDWORDS_MOST)
        retVal = 'Prepare: most';
    case uint16(movementTypes.HANDWORDS_DURING)
        retVal = 'Prepare: during';
    case uint16(movementTypes.HANDWORDS_NOW)
        retVal = 'Prepare: now';
    case uint16(movementTypes.HANDWORDS_SIZE)
        retVal = 'Prepare: size';
    case uint16(movementTypes.HANDWORDS_DEATH)
        retVal = 'Prepare: death';
    case uint16(movementTypes.HANDWORDS_SURPRISE)
        retVal = 'Prepare: surprise';
    case uint16(movementTypes.HANDWORDS_WORLD)
        retVal = 'Prepare: world';
    case uint16(movementTypes.HANDWORDS_HEAVY)
        retVal = 'Prepare: heavy';
    case uint16(movementTypes.HANDWORDS_BILL)
        retVal = 'Prepare: bill';
    case uint16(movementTypes.HANDWORDS_MONTH)
        retVal = 'Prepare: month';
    case uint16(movementTypes.HANDWORDS_ACCEPT)
        retVal = 'Prepare: accept';
    case uint16(movementTypes.HANDWORDS_POOR)
        retVal = 'Prepare: poor';
    case uint16(movementTypes.HANDWORDS_PEOPLE)
        retVal = 'Prepare: people';
    case uint16(movementTypes.HANDWORDS_LOAD)
        retVal = 'Prepare: load';
    case uint16(movementTypes.HANDWORDS_BET)
        retVal = 'Prepare: bet';
    case uint16(movementTypes.HANDWORDS_DIG)
        retVal = 'Prepare: dig';
    case uint16(movementTypes.HANDWORDS_STRAIGHT)
        retVal = 'Prepare: straight';
    case uint16(movementTypes.HANDWORDS_THE)
        retVal = 'Prepare: the';
    case uint16(movementTypes.HANDWORDS_FORWARD)
        retVal = 'Prepare: forward';
    case uint16(movementTypes.HANDWORDS_LEAVE)
        retVal = 'Prepare: leave';
    case uint16(movementTypes.HANDWORDS_LOT)
        retVal = 'Prepare: lot';
    case uint16(movementTypes.HANDWORDS_TOWN)
        retVal = 'Prepare: town';
    case uint16(movementTypes.HANDWORDS_CLEAN)
        retVal = 'Prepare: clean';
    case uint16(movementTypes.HANDWORDS_PHOTOGRAPH)
        retVal = 'Prepare: photograph';
    case uint16(movementTypes.HANDWORDS_TOGETHER)
        retVal = 'Prepare: together';
    case uint16(movementTypes.HANDWORDS_TRAVEL)
        retVal = 'Prepare: travel';
    case uint16(movementTypes.HANDWORDS_START)
        retVal = 'Prepare: start';
    case uint16(movementTypes.HANDWORDS_BESIDE)
        retVal = 'Prepare: beside';
    case uint16(movementTypes.HANDWORDS_CROSS)
        retVal = 'Prepare: cross';
    case uint16(movementTypes.HANDWORDS_STONE)
        retVal = 'Prepare: stone';
    case uint16(movementTypes.HANDWORDS_LOVE)
        retVal = 'Prepare: love';
    case uint16(movementTypes.HANDWORDS_SILLY)
        retVal = 'Prepare: silly';
    case uint16(movementTypes.HANDWORDS_OBVIOUS)
        retVal = 'Prepare: obvious';
    case uint16(movementTypes.HANDWORDS_LATE)
        retVal = 'Prepare: late';
    case uint16(movementTypes.HANDWORDS_MESS)
        retVal = 'Prepare: mess';
    case uint16(movementTypes.HANDWORDS_FAVOURITE)
        retVal = 'Prepare: favourite';
    case uint16(movementTypes.HANDWORDS_WORK)
        retVal = 'Prepare: work';
    case uint16(movementTypes.HANDWORDS_TRAIN)
        retVal = 'Prepare: train';
    case uint16(movementTypes.HANDWORDS_WILD)
        retVal = 'Prepare: wild';
    case uint16(movementTypes.HANDWORDS_STORY)
        retVal = 'Prepare: story';
    case uint16(movementTypes.HANDWORDS_TIE)
        retVal = 'Prepare: tie';
    case uint16(movementTypes.HANDWORDS_WINTER)
        retVal = 'Prepare: winter';
    case uint16(movementTypes.HANDWORDS_TEND)
        retVal = 'Prepare: tend';
    case uint16(movementTypes.HANDWORDS_SIMPLE)
        retVal = 'Prepare: simple';
    case uint16(movementTypes.HANDWORDS_SORT)
        retVal = 'Prepare: sort';
    case uint16(movementTypes.HANDWORDS_SUGGEST)
        retVal = 'Prepare: suggest';
    case uint16(movementTypes.HANDWORDS_BLOW)
        retVal = 'Prepare: blow';
    case uint16(movementTypes.HANDWORDS_TAIL)
        retVal = 'Prepare: tail';
    case uint16(movementTypes.HANDWORDS_SERVICE)
        retVal = 'Prepare: service';
    case uint16(movementTypes.HANDWORDS_BIG)
        retVal = 'Prepare: big';
    case uint16(movementTypes.HANDWORDS_HOLE)
        retVal = 'Prepare: hole';
    case uint16(movementTypes.HANDWORDS_NUMBER)
        retVal = 'Prepare: number';
    case uint16(movementTypes.HANDWORDS_THIRTY)
        retVal = 'Prepare: thirty';
    case uint16(movementTypes.HANDWORDS_WITHOUT)
        retVal = 'Prepare: without';
    case uint16(movementTypes.HANDWORDS_NECESSARY)
        retVal = 'Prepare: necessary';
    case uint16(movementTypes.HANDWORDS_NURSE)
        retVal = 'Prepare: nurse';
    case uint16(movementTypes.HANDWORDS_MIND)
        retVal = 'Prepare: mind';
    case uint16(movementTypes.HANDWORDS_END)
        retVal = 'Prepare: end';
    case uint16(movementTypes.HANDWORDS_KING)
        retVal = 'Prepare: king';
    case uint16(movementTypes.HANDWORDS_EACH)
        retVal = 'Prepare: each';
    case uint16(movementTypes.HANDWORDS_TOUCH)
        retVal = 'Prepare: touch';
    case uint16(movementTypes.HANDWORDS_WORRY)
        retVal = 'Prepare: worry';
    case uint16(movementTypes.HANDWORDS_ALMOST)
        retVal = 'Prepare: almost';
    case uint16(movementTypes.HANDWORDS_WOULD)
        retVal = 'Prepare: would';
    case uint16(movementTypes.HANDWORDS_HELP)
        retVal = 'Prepare: help';
    case uint16(movementTypes.HANDWORDS_SERIOUS)
        retVal = 'Prepare: serious';
    case uint16(movementTypes.HANDWORDS_CONSIDER)
        retVal = 'Prepare: consider';
    case uint16(movementTypes.HANDWORDS_LIFT)
        retVal = 'Prepare: lift';
    case uint16(movementTypes.HANDWORDS_OF)
        retVal = 'Prepare: of';
    case uint16(movementTypes.HANDWORDS_MILK)
        retVal = 'Prepare: milk';
    case uint16(movementTypes.HANDWORDS_ENTER)
        retVal = 'Prepare: enter';
    case uint16(movementTypes.HANDWORDS_GENTLE)
        retVal = 'Prepare: gentle';
    case uint16(movementTypes.HANDWORDS_RAISE)
        retVal = 'Prepare: raise';
    case uint16(movementTypes.HANDWORDS_DELICIOUS)
        retVal = 'Prepare: delicious';
    case uint16(movementTypes.HANDWORDS_MILLION)
        retVal = 'Prepare: million';
    case uint16(movementTypes.HANDWORDS_YES)
        retVal = 'Prepare: yes';
    case uint16(movementTypes.HANDWORDS_PLENTY)
        retVal = 'Prepare: plenty';
    case uint16(movementTypes.HANDWORDS_YELLOW)
        retVal = 'Prepare: yellow';
    case uint16(movementTypes.HANDWORDS_FATHER)
        retVal = 'Prepare: father';
    case uint16(movementTypes.HANDWORDS_GROUND)
        retVal = 'Prepare: ground';
    case uint16(movementTypes.HANDWORDS_SHOUT)
        retVal = 'Prepare: shout';
    case uint16(movementTypes.HANDWORDS_WHY)
        retVal = 'Prepare: why';
    case uint16(movementTypes.HANDWORDS_WHEN)
        retVal = 'Prepare: when';
    case uint16(movementTypes.HANDWORDS_HUNT)
        retVal = 'Prepare: hunt';
    case uint16(movementTypes.HANDWORDS_HELL)
        retVal = 'Prepare: hell';
    case uint16(movementTypes.HANDWORDS_TREE)
        retVal = 'Prepare: tree';
    case uint16(movementTypes.HANDWORDS_TRUST)
        retVal = 'Prepare: trust';
    case uint16(movementTypes.HANDWORDS_REMEMBER)
        retVal = 'Prepare: remember';
    case uint16(movementTypes.HANDWORDS_PERFECT)
        retVal = 'Prepare: perfect';
    case uint16(movementTypes.HANDWORDS_DEEP)
        retVal = 'Prepare: deep';
    case uint16(movementTypes.HANDWORDS_PAIR)
        retVal = 'Prepare: pair';
    case uint16(movementTypes.HANDWORDS_BOOK)
        retVal = 'Prepare: book';
    case uint16(movementTypes.HANDWORDS_KIND)
        retVal = 'Prepare: kind';
    case uint16(movementTypes.HANDWORDS_GO)
        retVal = 'Prepare: go';
    case uint16(movementTypes.HANDWORDS_PUSH)
        retVal = 'Prepare: push';
    case uint16(movementTypes.HANDWORDS_CAUSE)
        retVal = 'Prepare: cause';
    case uint16(movementTypes.HANDWORDS_BELOW)
        retVal = 'Prepare: below';
    case uint16(movementTypes.HANDWORDS_UNDERNEATH)
        retVal = 'Prepare: underneath';
    case uint16(movementTypes.HANDWORDS_OFFER)
        retVal = 'Prepare: offer';
    case uint16(movementTypes.HANDWORDS_AFTERNOON)
        retVal = 'Prepare: afternoon';
    case uint16(movementTypes.HANDWORDS_FRONT)
        retVal = 'Prepare: front';
    case uint16(movementTypes.HANDWORDS_WHETHER)
        retVal = 'Prepare: whether';
    case uint16(movementTypes.HANDWORDS_LIST)
        retVal = 'Prepare: list';
    case uint16(movementTypes.HANDWORDS_AFRAID)
        retVal = 'Prepare: afraid';
    case uint16(movementTypes.HANDWORDS_NEW)
        retVal = 'Prepare: new';
    case uint16(movementTypes.HANDWORDS_RISE)
        retVal = 'Prepare: rise';
    case uint16(movementTypes.HANDWORDS_HIDE)
        retVal = 'Prepare: hide';
    case uint16(movementTypes.HANDWORDS_BOTHER)
        retVal = 'Prepare: bother';
    case uint16(movementTypes.HANDWORDS_GLANCE)
        retVal = 'Prepare: glance';
    case uint16(movementTypes.HANDWORDS_CLOCK)
        retVal = 'Prepare: clock';
    case uint16(movementTypes.HANDWORDS_AHEAD)
        retVal = 'Prepare: ahead';
    case uint16(movementTypes.HANDWORDS_OVER)
        retVal = 'Prepare: over';
    case uint16(movementTypes.HANDWORDS_WHEEL)
        retVal = 'Prepare: wheel';
    case uint16(movementTypes.HANDWORDS_ALONG)
        retVal = 'Prepare: along';
    case uint16(movementTypes.HANDWORDS_BOTTOM)
        retVal = 'Prepare: bottom';
    case uint16(movementTypes.HANDWORDS_FOOD)
        retVal = 'Prepare: food';
    case uint16(movementTypes.HANDWORDS_RETURN)
        retVal = 'Prepare: return';
    case uint16(movementTypes.HANDWORDS_SELF)
        retVal = 'Prepare: self';
    case uint16(movementTypes.HANDWORDS_SONG)
        retVal = 'Prepare: song';
    case uint16(movementTypes.HANDWORDS_THIRST)
        retVal = 'Prepare: thirst';
    case uint16(movementTypes.HANDWORDS_ROUND)
        retVal = 'Prepare: round';
    case uint16(movementTypes.HANDWORDS_STEAL)
        retVal = 'Prepare: steal';
    case uint16(movementTypes.HANDWORDS_UNDERSTAND)
        retVal = 'Prepare: understand';
    case uint16(movementTypes.HANDWORDS_TRACK)
        retVal = 'Prepare: track';
    case uint16(movementTypes.HANDWORDS_COOL)
        retVal = 'Prepare: cool';
    case uint16(movementTypes.HANDWORDS_ALWAYS)
        retVal = 'Prepare: always';
    case uint16(movementTypes.HANDWORDS_VOICE)
        retVal = 'Prepare: voice';
    case uint16(movementTypes.HANDWORDS_HUMAN)
        retVal = 'Prepare: human';
    case uint16(movementTypes.HANDWORDS_TWELVE)
        retVal = 'Prepare: twelve';
    case uint16(movementTypes.HANDWORDS_RID)
        retVal = 'Prepare: rid';
    case uint16(movementTypes.HANDWORDS_CASE)
        retVal = 'Prepare: case';
    case uint16(movementTypes.HANDWORDS_RUN)
        retVal = 'Prepare: run';
    case uint16(movementTypes.HANDWORDS_DEAR)
        retVal = 'Prepare: dear';
    case uint16(movementTypes.HANDWORDS_BEAT)
        retVal = 'Prepare: beat';
    case uint16(movementTypes.HANDWORDS_CONCERN)
        retVal = 'Prepare: concern';
    case uint16(movementTypes.HANDWORDS_PROBLEM)
        retVal = 'Prepare: problem';
    case uint16(movementTypes.HANDWORDS_PAPER)
        retVal = 'Prepare: paper';
    case uint16(movementTypes.HANDWORDS_NONE)
        retVal = 'Prepare: none';
    case uint16(movementTypes.HANDWORDS_NECK)
        retVal = 'Prepare: neck';
    case uint16(movementTypes.HANDWORDS_SIX)
        retVal = 'Prepare: six';
    case uint16(movementTypes.HANDWORDS_RIVER)
        retVal = 'Prepare: river';
    case uint16(movementTypes.HANDWORDS_RICH)
        retVal = 'Prepare: rich';
    case uint16(movementTypes.HANDWORDS_RING)
        retVal = 'Prepare: ring';
    case uint16(movementTypes.HANDWORDS_ABOUT)
        retVal = 'Prepare: about';
    case uint16(movementTypes.HANDWORDS_BATH)
        retVal = 'Prepare: bath';
    case uint16(movementTypes.HANDWORDS_IT)
        retVal = 'Prepare: it';
    case uint16(movementTypes.HANDWORDS_FORCE)
        retVal = 'Prepare: force';
    case uint16(movementTypes.HANDWORDS_SHOULD)
        retVal = 'Prepare: should';
    case uint16(movementTypes.HANDWORDS_CHECK)
        retVal = 'Prepare: check';
    case uint16(movementTypes.HANDWORDS_ASHAMED)
        retVal = 'Prepare: ashamed';
    case uint16(movementTypes.HANDWORDS_STUDY)
        retVal = 'Prepare: study';
    case uint16(movementTypes.HANDWORDS_TURN)
        retVal = 'Prepare: turn';
    case uint16(movementTypes.HANDWORDS_CONTINUE)
        retVal = 'Prepare: continue';
    case uint16(movementTypes.HANDWORDS_ARM)
        retVal = 'Prepare: arm';
    case uint16(movementTypes.HANDWORDS_YARD)
        retVal = 'Prepare: yard';
    case uint16(movementTypes.HANDWORDS_SUNDAY)
        retVal = 'Prepare: sunday';
    case uint16(movementTypes.HANDWORDS_DAD)
        retVal = 'Prepare: dad';
    case uint16(movementTypes.HANDWORDS_PRESS)
        retVal = 'Prepare: press';
    case uint16(movementTypes.HANDWORDS_FINAL)
        retVal = 'Prepare: final';
    case uint16(movementTypes.HANDWORDS_CENTRE)
        retVal = 'Prepare: centre';
    case uint16(movementTypes.HANDWORDS_DEFINITE)
        retVal = 'Prepare: definite';
    case uint16(movementTypes.HANDWORDS_SEE)
        retVal = 'Prepare: see';
    case uint16(movementTypes.HANDWORDS_PREPARE)
        retVal = 'Prepare: prepare';
    case uint16(movementTypes.HANDWORDS_SIDE)
        retVal = 'Prepare: side';
    case uint16(movementTypes.HANDWORDS_HANG)
        retVal = 'Prepare: hang';
    case uint16(movementTypes.HANDWORDS_FRIGHT)
        retVal = 'Prepare: fright';
    case uint16(movementTypes.HANDWORDS_PAIN)
        retVal = 'Prepare: pain';
    case uint16(movementTypes.HANDWORDS_NEED)
        retVal = 'Prepare: need';
    case uint16(movementTypes.HANDWORDS_FOLLOW)
        retVal = 'Prepare: follow';
    case uint16(movementTypes.HANDWORDS_ARRIVE)
        retVal = 'Prepare: arrive';
    case uint16(movementTypes.HANDWORDS_PROTECT)
        retVal = 'Prepare: protect';
    case uint16(movementTypes.HANDWORDS_FINGER)
        retVal = 'Prepare: finger';
    case uint16(movementTypes.HANDWORDS_REST)
        retVal = 'Prepare: rest';
    case uint16(movementTypes.HANDWORDS_ROAD)
        retVal = 'Prepare: road';
    case uint16(movementTypes.HANDWORDS_TOWARD)
        retVal = 'Prepare: toward';
    case uint16(movementTypes.HANDWORDS_THINK)
        retVal = 'Prepare: think';
    case uint16(movementTypes.HANDWORDS_SAY)
        retVal = 'Prepare: say';
    case uint16(movementTypes.HANDWORDS_FIVE)
        retVal = 'Prepare: five';
    case uint16(movementTypes.HANDWORDS_LEAD)
        retVal = 'Prepare: lead';
    case uint16(movementTypes.HANDWORDS_COMPLETE)
        retVal = 'Prepare: complete';
    case uint16(movementTypes.HANDWORDS_EAST)
        retVal = 'Prepare: east';
    case uint16(movementTypes.HANDWORDS_YEAR)
        retVal = 'Prepare: year';
    case uint16(movementTypes.HANDWORDS_SMALL)
        retVal = 'Prepare: small';
    case uint16(movementTypes.HANDWORDS_EVENING)
        retVal = 'Prepare: evening';
    case uint16(movementTypes.HANDWORDS_ANOTHER)
        retVal = 'Prepare: another';
    case uint16(movementTypes.HANDWORDS_FOUR)
        retVal = 'Prepare: four';
    case uint16(movementTypes.HANDWORDS_NOTICE)
        retVal = 'Prepare: notice';
    case uint16(movementTypes.HANDWORDS_COME)
        retVal = 'Prepare: come';
    case uint16(movementTypes.HANDWORDS_PRESENT)
        retVal = 'Prepare: present';
    case uint16(movementTypes.HANDWORDS_POP)
        retVal = 'Prepare: pop';
    case uint16(movementTypes.HANDWORDS_TO)
        retVal = 'Prepare: to';
    case uint16(movementTypes.HANDWORDS_WIDE)
        retVal = 'Prepare: wide';
    case uint16(movementTypes.HANDWORDS_ADMIT)
        retVal = 'Prepare: admit';
    case uint16(movementTypes.HANDWORDS_THREE)
        retVal = 'Prepare: three';
    case uint16(movementTypes.HANDWORDS_BUSH)
        retVal = 'Prepare: bush';
    case uint16(movementTypes.HANDWORDS_UP)
        retVal = 'Prepare: up';
    case uint16(movementTypes.HANDWORDS_AGAINST)
        retVal = 'Prepare: against';
    case uint16(movementTypes.HANDWORDS_AGE)
        retVal = 'Prepare: age';
    case uint16(movementTypes.HANDWORDS_COUPLE)
        retVal = 'Prepare: couple';
    case uint16(movementTypes.HANDWORDS_FIELD)
        retVal = 'Prepare: field';
    case uint16(movementTypes.HANDWORDS_LIFE)
        retVal = 'Prepare: life';
    case uint16(movementTypes.HANDWORDS_TOOTH)
        retVal = 'Prepare: tooth';
    case uint16(movementTypes.HANDWORDS_UGLY)
        retVal = 'Prepare: ugly';
    case uint16(movementTypes.HANDWORDS_WANT)
        retVal = 'Prepare: want';
    case uint16(movementTypes.HANDWORDS_ODD)
        retVal = 'Prepare: odd';
    case uint16(movementTypes.HANDWORDS_LUNCH)
        retVal = 'Prepare: lunch';
    case uint16(movementTypes.HANDWORDS_PIECE)
        retVal = 'Prepare: piece';
    case uint16(movementTypes.HANDWORDS_FACT)
        retVal = 'Prepare: fact';
    case uint16(movementTypes.HANDWORDS_WONDER)
        retVal = 'Prepare: wonder';
    case uint16(movementTypes.HANDWORDS_WEAR)
        retVal = 'Prepare: wear';
    case uint16(movementTypes.HANDWORDS_EAR)
        retVal = 'Prepare: ear';
    case uint16(movementTypes.HANDWORDS_AFTER)
        retVal = 'Prepare: after';
    case uint16(movementTypes.HANDWORDS_FLAT)
        retVal = 'Prepare: flat';
    case uint16(movementTypes.HANDWORDS_SWIM)
        retVal = 'Prepare: swim';
    case uint16(movementTypes.HANDWORDS_APPEAR)
        retVal = 'Prepare: appear';
    case uint16(movementTypes.HANDWORDS_WORSE)
        retVal = 'Prepare: worse';
    case uint16(movementTypes.HANDWORDS_RULE)
        retVal = 'Prepare: rule';
    case uint16(movementTypes.HANDWORDS_USE)
        retVal = 'Prepare: use';
    case uint16(movementTypes.HANDWORDS_BELIEVE)
        retVal = 'Prepare: believe';
    case uint16(movementTypes.HANDWORDS_THROW)
        retVal = 'Prepare: throw';
    case uint16(movementTypes.HANDWORDS_SQUARE)
        retVal = 'Prepare: square';
    case uint16(movementTypes.HANDWORDS_TWO)
        retVal = 'Prepare: two';
    case uint16(movementTypes.HANDWORDS_CITY)
        retVal = 'Prepare: city';
    case uint16(movementTypes.HANDWORDS_TEACH)
        retVal = 'Prepare: teach';
    case uint16(movementTypes.HANDWORDS_AROUND)
        retVal = 'Prepare: around';
    case uint16(movementTypes.HANDWORDS_ONE)
        retVal = 'Prepare: one';
    case uint16(movementTypes.HANDWORDS_EVEN)
        retVal = 'Prepare: even';
    case uint16(movementTypes.HANDWORDS_POSSIBLE)
        retVal = 'Prepare: possible';
    case uint16(movementTypes.HANDWORDS_BRING)
        retVal = 'Prepare: bring';
    case uint16(movementTypes.HANDWORDS_SHORT)
        retVal = 'Prepare: short';
    case uint16(movementTypes.HANDWORDS_CHANGE)
        retVal = 'Prepare: change';
    case uint16(movementTypes.HANDWORDS_DISCOVER)
        retVal = 'Prepare: discover';
    case uint16(movementTypes.HANDWORDS_STICK)
        retVal = 'Prepare: stick';
    case uint16(movementTypes.HANDWORDS_SENSE)
        retVal = 'Prepare: sense';
    case uint16(movementTypes.HANDWORDS_PROBABLY)
        retVal = 'Prepare: probably';
    case uint16(movementTypes.HANDWORDS_PASS)
        retVal = 'Prepare: pass';
    case uint16(movementTypes.HANDWORDS_BODY)
        retVal = 'Prepare: body';
    case uint16(movementTypes.HANDWORDS_CHRISTMAS)
        retVal = 'Prepare: christmas';
    case uint16(movementTypes.HANDWORDS_PROGRAMME)
        retVal = 'Prepare: programme';
    case uint16(movementTypes.HANDWORDS_WIN)
        retVal = 'Prepare: win';
    case uint16(movementTypes.HANDWORDS_GUY)
        retVal = 'Prepare: guy';
    case uint16(movementTypes.HANDWORDS_RATE)
        retVal = 'Prepare: rate';
    case uint16(movementTypes.HANDWORDS_KICK)
        retVal = 'Prepare: kick';
    case uint16(movementTypes.HANDWORDS_FISH)
        retVal = 'Prepare: fish';
    case uint16(movementTypes.HANDWORDS_INSURE)
        retVal = 'Prepare: insure';
    case uint16(movementTypes.HANDWORDS_GIVE)
        retVal = 'Prepare: give';
    case uint16(movementTypes.HANDWORDS_COOK)
        retVal = 'Prepare: cook';
    case uint16(movementTypes.HANDWORDS_WEEK)
        retVal = 'Prepare: week';
    case uint16(movementTypes.HANDWORDS_CHOOSE)
        retVal = 'Prepare: choose';
    case uint16(movementTypes.HANDWORDS_STARE)
        retVal = 'Prepare: stare';
    case uint16(movementTypes.HANDWORDS_TELEVISION)
        retVal = 'Prepare: television';
    case uint16(movementTypes.HANDWORDS_HUSBAND)
        retVal = 'Prepare: husband';
    case uint16(movementTypes.HANDWORDS_SEVERAL)
        retVal = 'Prepare: several';
    case uint16(movementTypes.HANDWORDS_STORE)
        retVal = 'Prepare: store';
    case uint16(movementTypes.HANDWORDS_WRITE)
        retVal = 'Prepare: write';
    case uint16(movementTypes.HANDWORDS_WAKE)
        retVal = 'Prepare: wake';
    case uint16(movementTypes.HANDWORDS_DREAM)
        retVal = 'Prepare: dream';
    case uint16(movementTypes.HANDWORDS_EVERY)
        retVal = 'Prepare: every';
    case uint16(movementTypes.HANDWORDS_PRICE)
        retVal = 'Prepare: price';
    case uint16(movementTypes.HANDWORDS_SHIRT)
        retVal = 'Prepare: shirt';
    case uint16(movementTypes.HANDWORDS_DIFFERENT)
        retVal = 'Prepare: different';
    case uint16(movementTypes.HANDWORDS_ENJOY)
        retVal = 'Prepare: enjoy';
    case uint16(movementTypes.HANDWORDS_COLLEGE)
        retVal = 'Prepare: college';
    case uint16(movementTypes.HANDWORDS_ZERO)
        retVal = 'Prepare: zero';
    case uint16(movementTypes.HANDWORDS_SOUTH)
        retVal = 'Prepare: south';
    case uint16(movementTypes.HANDWORDS_TELEPHONE)
        retVal = 'Prepare: telephone';
    case uint16(movementTypes.HANDWORDS_DIFFICULT)
        retVal = 'Prepare: difficult';
    case uint16(movementTypes.HANDWORDS_SUIT)
        retVal = 'Prepare: suit';
    case uint16(movementTypes.HANDWORDS_WATER)
        retVal = 'Prepare: water';
    case uint16(movementTypes.HANDWORDS_UNLESS)
        retVal = 'Prepare: unless';
    case uint16(movementTypes.HANDWORDS_ANIMAL)
        retVal = 'Prepare: animal';
    case uint16(movementTypes.HANDWORDS_PLEASE)
        retVal = 'Prepare: please';
    case uint16(movementTypes.HANDWORDS_REALISE)
        retVal = 'Prepare: realise';
    case uint16(movementTypes.HANDWORDS_MRS)
        retVal = 'Prepare: mrs';
    case uint16(movementTypes.HANDWORDS_APPARENT)
        retVal = 'Prepare: apparent';
    case uint16(movementTypes.HANDWORDS_RAIN)
        retVal = 'Prepare: rain';
    case uint16(movementTypes.HANDWORDS_HORRIBLE)
        retVal = 'Prepare: horrible';
    case uint16(movementTypes.HANDWORDS_EDUCATE)
        retVal = 'Prepare: educate';
    case uint16(movementTypes.HANDWORDS_THURSDAY)
        retVal = 'Prepare: thursday';
    case uint16(movementTypes.HANDWORDS_POWER)
        retVal = 'Prepare: power';
    case uint16(movementTypes.HANDWORDS_STUPID)
        retVal = 'Prepare: stupid';
    case uint16(movementTypes.HANDWORDS_ANY)
        retVal = 'Prepare: any';
    case uint16(movementTypes.HANDWORDS_JUST)
        retVal = 'Prepare: just';
    case uint16(movementTypes.HANDWORDS_SECOND)
        retVal = 'Prepare: second';
    case uint16(movementTypes.HANDWORDS_KEEP)
        retVal = 'Prepare: keep';
    case uint16(movementTypes.HANDWORDS_SCHOOL)
        retVal = 'Prepare: school';
    case uint16(movementTypes.HANDWORDS_HEAT)
        retVal = 'Prepare: heat';
    case uint16(movementTypes.HANDWORDS_FOREST)
        retVal = 'Prepare: forest';
    case uint16(movementTypes.HANDWORDS_EGG)
        retVal = 'Prepare: egg';
    case uint16(movementTypes.HANDWORDS_WAY)
        retVal = 'Prepare: way';
    case uint16(movementTypes.HANDWORDS_BAD)
        retVal = 'Prepare: bad';
    case uint16(movementTypes.HANDWORDS_GAME)
        retVal = 'Prepare: game';
    case uint16(movementTypes.HANDWORDS_BRIGHT)
        retVal = 'Prepare: bright';
    case uint16(movementTypes.HANDWORDS_STAGE)
        retVal = 'Prepare: stage';
    case uint16(movementTypes.HANDWORDS_CERTAIN)
        retVal = 'Prepare: certain';
    case uint16(movementTypes.HANDWORDS_MASTER)
        retVal = 'Prepare: master';
    case uint16(movementTypes.HANDWORDS_SHARE)
        retVal = 'Prepare: share';
    case uint16(movementTypes.HANDWORDS_SMILE)
        retVal = 'Prepare: smile';
    case uint16(movementTypes.HANDWORDS_INSTEAD)
        retVal = 'Prepare: instead';
    case uint16(movementTypes.HANDWORDS_SNOW)
        retVal = 'Prepare: snow';
    case uint16(movementTypes.HANDWORDS_PRETTY)
        retVal = 'Prepare: pretty';
    case uint16(movementTypes.HANDWORDS_BANK)
        retVal = 'Prepare: bank';
    case uint16(movementTypes.HANDWORDS_BREATH)
        retVal = 'Prepare: breath';
    case uint16(movementTypes.HANDWORDS_FRIEND)
        retVal = 'Prepare: friend';
    case uint16(movementTypes.HANDWORDS_WOMAN)
        retVal = 'Prepare: woman';
    case uint16(movementTypes.HANDWORDS_GUESS)
        retVal = 'Prepare: guess';
    case uint16(movementTypes.HANDWORDS_SISTER)
        retVal = 'Prepare: sister';
    case uint16(movementTypes.HANDWORDS_HOLIDAY)
        retVal = 'Prepare: holiday';
    case uint16(movementTypes.HANDWORDS_ORDER)
        retVal = 'Prepare: order';
    case uint16(movementTypes.HANDWORDS_TAPE)
        retVal = 'Prepare: tape';
    case uint16(movementTypes.HANDWORDS_KILL)
        retVal = 'Prepare: kill';
    case uint16(movementTypes.HANDWORDS_DOOR)
        retVal = 'Prepare: door';
    case uint16(movementTypes.HANDWORDS_ABLE)
        retVal = 'Prepare: able';
    case uint16(movementTypes.HANDWORDS_WITH)
        retVal = 'Prepare: with';
    case uint16(movementTypes.HANDWORDS_SORRY)
        retVal = 'Prepare: sorry';
    case uint16(movementTypes.HANDWORDS_SINCE)
        retVal = 'Prepare: since';
    case uint16(movementTypes.HANDWORDS_SATURDAY)
        retVal = 'Prepare: saturday';
    case uint16(movementTypes.HANDWORDS_BILLION)
        retVal = 'Prepare: billion';
    case uint16(movementTypes.HANDWORDS_SEEM)
        retVal = 'Prepare: seem';
    case uint16(movementTypes.HANDWORDS_SMELL)
        retVal = 'Prepare: smell';
    case uint16(movementTypes.HANDWORDS_INFORM)
        retVal = 'Prepare: inform';
    case uint16(movementTypes.HANDWORDS_SMOKE)
        retVal = 'Prepare: smoke';
    case uint16(movementTypes.HANDWORDS_WEIGHT)
        retVal = 'Prepare: weight';
    case uint16(movementTypes.HANDWORDS_HATE)
        retVal = 'Prepare: hate';
    case uint16(movementTypes.HANDWORDS_FAT)
        retVal = 'Prepare: fat';
    case uint16(movementTypes.HANDWORDS_BEAR)
        retVal = 'Prepare: bear';
    case uint16(movementTypes.HANDWORDS_EITHER)
        retVal = 'Prepare: either';
    case uint16(movementTypes.HANDWORDS_BOX)
        retVal = 'Prepare: box';
    case uint16(movementTypes.HANDWORDS_WATCH)
        retVal = 'Prepare: watch';
    case uint16(movementTypes.HANDWORDS_ROOM)
        retVal = 'Prepare: room';
    case uint16(movementTypes.HANDWORDS_YESTERDAY)
        retVal = 'Prepare: yesterday';
    case uint16(movementTypes.HANDWORDS_PICTURE)
        retVal = 'Prepare: picture';
    case uint16(movementTypes.HANDWORDS_FROM)
        retVal = 'Prepare: from';
    case uint16(movementTypes.HANDWORDS_BUILD)
        retVal = 'Prepare: build';
    case uint16(movementTypes.HANDWORDS_KNOW)
        retVal = 'Prepare: know';
    case uint16(movementTypes.HANDWORDS_ALSO)
        retVal = 'Prepare: also';
    case uint16(movementTypes.HANDWORDS_STILL)
        retVal = 'Prepare: still';
    case uint16(movementTypes.HANDWORDS_WAIT)
        retVal = 'Prepare: wait';
    case uint16(movementTypes.HANDWORDS_LIE)
        retVal = 'Prepare: lie';
    case uint16(movementTypes.HANDWORDS_BUY)
        retVal = 'Prepare: buy';
    case uint16(movementTypes.HANDWORDS_DOUBLE)
        retVal = 'Prepare: double';
    case uint16(movementTypes.HANDWORDS_LOSE)
        retVal = 'Prepare: lose';
    case uint16(movementTypes.HANDWORDS_WOOD)
        retVal = 'Prepare: wood';
    case uint16(movementTypes.HANDWORDS_NEIGHBOUR)
        retVal = 'Prepare: neighbour';
    case uint16(movementTypes.HANDWORDS_MANAGE)
        retVal = 'Prepare: manage';
    case uint16(movementTypes.HANDWORDS_BREAD)
        retVal = 'Prepare: bread';
    case uint16(movementTypes.HANDWORDS_SECURE)
        retVal = 'Prepare: secure';
    case uint16(movementTypes.HANDWORDS_PULL)
        retVal = 'Prepare: pull';
    case uint16(movementTypes.HANDWORDS_PAINT)
        retVal = 'Prepare: paint';
    case uint16(movementTypes.HANDWORDS_WORTH)
        retVal = 'Prepare: worth';
    case uint16(movementTypes.HANDWORDS_CARRY)
        retVal = 'Prepare: carry';
    case uint16(movementTypes.HANDWORDS_BLACK)
        retVal = 'Prepare: black';
    case uint16(movementTypes.HANDWORDS_STRANGE)
        retVal = 'Prepare: strange';
    case uint16(movementTypes.HANDWORDS_COLOUR)
        retVal = 'Prepare: colour';
    case uint16(movementTypes.HANDWORDS_FINISH)
        retVal = 'Prepare: finish';
    case uint16(movementTypes.HANDWORDS_COUNTRY)
        retVal = 'Prepare: country';
    case uint16(movementTypes.HANDWORDS_BECOME)
        retVal = 'Prepare: become';
    case uint16(movementTypes.HANDWORDS_SOFT)
        retVal = 'Prepare: soft';
    case uint16(movementTypes.HANDWORDS_LIP)
        retVal = 'Prepare: lip';
    case uint16(movementTypes.HANDWORDS_ROCK)
        retVal = 'Prepare: rock';
    case uint16(movementTypes.HANDWORDS_TASTE)
        retVal = 'Prepare: taste';
    case uint16(movementTypes.HANDWORDS_AND)
        retVal = 'Prepare: and';
    case uint16(movementTypes.HANDWORDS_GENERAL)
        retVal = 'Prepare: general';
    case uint16(movementTypes.HANDWORDS_BASE)
        retVal = 'Prepare: base';
    case uint16(movementTypes.HANDWORDS_AREA)
        retVal = 'Prepare: area';
    case uint16(movementTypes.HANDWORDS_LAY)
        retVal = 'Prepare: lay';
    case uint16(movementTypes.HANDWORDS_KISS)
        retVal = 'Prepare: kiss';
    case uint16(movementTypes.HANDWORDS_IN)
        retVal = 'Prepare: in';
    case uint16(movementTypes.HANDWORDS_RATHER)
        retVal = 'Prepare: rather';
    case uint16(movementTypes.HANDWORDS_AGREE)
        retVal = 'Prepare: agree';
    case uint16(movementTypes.HANDWORDS_HOSPITAL)
        retVal = 'Prepare: hospital';
    case uint16(movementTypes.HANDWORDS_TRY)
        retVal = 'Prepare: try';
    case uint16(movementTypes.HANDWORDS_SETTLE)
        retVal = 'Prepare: settle';
    case uint16(movementTypes.HANDWORDS_DEAD)
        retVal = 'Prepare: dead';
    case uint16(movementTypes.HANDWORDS_CAN)
        retVal = 'Prepare: can';
    case uint16(movementTypes.HANDWORDS_TOP)
        retVal = 'Prepare: top';
    case uint16(movementTypes.HANDWORDS_HONOUR)
        retVal = 'Prepare: honour';
    case uint16(movementTypes.HANDWORDS_TAX)
        retVal = 'Prepare: tax';
    case uint16(movementTypes.HANDWORDS_FALL)
        retVal = 'Prepare: fall';
    case uint16(movementTypes.HANDWORDS_MISS)
        retVal = 'Prepare: miss';
    case uint16(movementTypes.HANDWORDS_LIGHT)
        retVal = 'Prepare: light';
    case uint16(movementTypes.HANDWORDS_SICK)
        retVal = 'Prepare: sick';
    case uint16(movementTypes.HANDWORDS_PARTICULAR)
        retVal = 'Prepare: particular';
    case uint16(movementTypes.HANDWORDS_TEST)
        retVal = 'Prepare: test';
    case uint16(movementTypes.HANDWORDS_DINNER)
        retVal = 'Prepare: dinner';
    case uint16(movementTypes.HANDWORDS_SON)
        retVal = 'Prepare: son';
    case uint16(movementTypes.HANDWORDS_NATURE)
        retVal = 'Prepare: nature';
    case uint16(movementTypes.HANDWORDS_WHITE)
        retVal = 'Prepare: white';
    case uint16(movementTypes.HANDWORDS_BUT)
        retVal = 'Prepare: but';
    case uint16(movementTypes.HANDWORDS_MANY)
        retVal = 'Prepare: many';
    case uint16(movementTypes.HANDWORDS_PARENT)
        retVal = 'Prepare: parent';
    case uint16(movementTypes.HANDWORDS_MONDAY)
        retVal = 'Prepare: monday';
    case uint16(movementTypes.HANDWORDS_BEAUTY)
        retVal = 'Prepare: beauty';
    case uint16(movementTypes.HANDWORDS_MOVE)
        retVal = 'Prepare: move';
    case uint16(movementTypes.HANDWORDS_BABY)
        retVal = 'Prepare: baby';
    case uint16(movementTypes.HANDWORDS_THEN)
        retVal = 'Prepare: then';
    case uint16(movementTypes.HANDWORDS_OIL)
        retVal = 'Prepare: oil';
    case uint16(movementTypes.HANDWORDS_JOIN)
        retVal = 'Prepare: join';
    case uint16(movementTypes.HANDWORDS_GRASS)
        retVal = 'Prepare: grass';
    case uint16(movementTypes.HANDWORDS_HAPPEN)
        retVal = 'Prepare: happen';
    case uint16(movementTypes.HANDWORDS_PACK)
        retVal = 'Prepare: pack';
    case uint16(movementTypes.HANDWORDS_EASY)
        retVal = 'Prepare: easy';
    case uint16(movementTypes.HANDWORDS_DEGREE)
        retVal = 'Prepare: degree';
    case uint16(movementTypes.HANDWORDS_ARRANGE)
        retVal = 'Prepare: arrange';
    case uint16(movementTypes.HANDWORDS_MAKE)
        retVal = 'Prepare: make';
    case uint16(movementTypes.HANDWORDS_BEST)
        retVal = 'Prepare: best';
    case uint16(movementTypes.HANDWORDS_SUBJECT)
        retVal = 'Prepare: subject';
    case uint16(movementTypes.HANDWORDS_SHY)
        retVal = 'Prepare: shy';
    case uint16(movementTypes.HANDWORDS_HARDLY)
        retVal = 'Prepare: hardly';
    case uint16(movementTypes.HANDWORDS_PARTY)
        retVal = 'Prepare: party';
    case uint16(movementTypes.HANDWORDS_POUND)
        retVal = 'Prepare: pound';
    case uint16(movementTypes.HANDWORDS_PAST)
        retVal = 'Prepare: past';
    case uint16(movementTypes.HANDWORDS_I)
        retVal = 'Prepare: i';
    case uint16(movementTypes.HANDWORDS_MOUTH)
        retVal = 'Prepare: mouth';
    case uint16(movementTypes.HANDWORDS_FEW)
        retVal = 'Prepare: few';
    case uint16(movementTypes.HANDWORDS_RIGHTS)
        retVal = 'Prepare: rights';
    case uint16(movementTypes.HANDWORDS_LONG)
        retVal = 'Prepare: long';
    case uint16(movementTypes.HANDWORDS_CLIMB)
        retVal = 'Prepare: climb';
    case uint16(movementTypes.HANDWORDS_YOUNG)
        retVal = 'Prepare: young';
    case uint16(movementTypes.HANDWORDS_CRAZY)
        retVal = 'Prepare: crazy';
    case uint16(movementTypes.HANDWORDS_ISSUE)
        retVal = 'Prepare: issue';
    case uint16(movementTypes.HANDWORDS_FELLOW)
        retVal = 'Prepare: fellow';
    case uint16(movementTypes.HANDWORDS_MIGHT)
        retVal = 'Prepare: might';
    case uint16(movementTypes.HANDWORDS_SAME)
        retVal = 'Prepare: same';
    case uint16(movementTypes.HANDWORDS_INVOLVE)
        retVal = 'Prepare: involve';
    case uint16(movementTypes.HANDWORDS_SWEET)
        retVal = 'Prepare: sweet';
    case uint16(movementTypes.HANDWORDS_SPRING)
        retVal = 'Prepare: spring';
    case uint16(movementTypes.HANDWORDS_NAME)
        retVal = 'Prepare: name';
    case uint16(movementTypes.HANDWORDS_ALL)
        retVal = 'Prepare: all';
    case uint16(movementTypes.HANDWORDS_WISH)
        retVal = 'Prepare: wish';
    case uint16(movementTypes.HANDWORDS_ROUGH)
        retVal = 'Prepare: rough';
    case uint16(movementTypes.HANDWORDS_UPON)
        retVal = 'Prepare: upon';
    case uint16(movementTypes.HANDWORDS_EYE)
        retVal = 'Prepare: eye';
    case uint16(movementTypes.HANDWORDS_TOTAL)
        retVal = 'Prepare: total';
    case uint16(movementTypes.HANDWORDS_OTHER)
        retVal = 'Prepare: other';
    case uint16(movementTypes.HANDWORDS_HUNDRED)
        retVal = 'Prepare: hundred';
    case uint16(movementTypes.HANDWORDS_SUPPORT)
        retVal = 'Prepare: support';
    case uint16(movementTypes.HANDWORDS_DRESS)
        retVal = 'Prepare: dress';
    case uint16(movementTypes.HANDWORDS_CLASS)
        retVal = 'Prepare: class';
    case uint16(movementTypes.HANDWORDS_SHAKE)
        retVal = 'Prepare: shake';
    case uint16(movementTypes.HANDWORDS_SHALL)
        retVal = 'Prepare: shall';
    case uint16(movementTypes.HANDWORDS_JOB)
        retVal = 'Prepare: job';
    case uint16(movementTypes.HANDWORDS_READY)
        retVal = 'Prepare: ready';
    case uint16(movementTypes.HANDWORDS_SCARE)
        retVal = 'Prepare: scare';
    case uint16(movementTypes.HANDWORDS_MAIN)
        retVal = 'Prepare: main';
    case uint16(movementTypes.HANDWORDS_DRAW)
        retVal = 'Prepare: draw';
    case uint16(movementTypes.HANDWORDS_RABBIT)
        retVal = 'Prepare: rabbit';
    case uint16(movementTypes.HANDWORDS_HERE)
        retVal = 'Prepare: here';
    case uint16(movementTypes.HANDWORDS_FIRE)
        retVal = 'Prepare: fire';
    case uint16(movementTypes.HANDWORDS_NEAT)
        retVal = 'Prepare: neat';
    case uint16(movementTypes.HANDWORDS_BOAT)
        retVal = 'Prepare: boat';
    case uint16(movementTypes.HANDWORDS_READ)
        retVal = 'Prepare: read';
    case uint16(movementTypes.HANDWORDS_GLASS)
        retVal = 'Prepare: glass';
    case uint16(movementTypes.HANDWORDS_WEST)
        retVal = 'Prepare: west';
    case uint16(movementTypes.HANDWORDS_FREEZE)
        retVal = 'Prepare: freeze';
    case uint16(movementTypes.HANDWORDS_BONE)
        retVal = 'Prepare: bone';
    case uint16(movementTypes.HANDWORDS_GOOD)
        retVal = 'Prepare: good';
    case uint16(movementTypes.HANDWORDS_REACH)
        retVal = 'Prepare: reach';
    case uint16(movementTypes.HANDWORDS_DO)
        retVal = 'Prepare: do';
    case uint16(movementTypes.HANDWORDS_CONTROL)
        retVal = 'Prepare: control';
    case uint16(movementTypes.HANDWORDS_OLD)
        retVal = 'Prepare: old';
    case uint16(movementTypes.HANDWORDS_OR)
        retVal = 'Prepare: or';
    case uint16(movementTypes.HANDWORDS_ENGINE)
        retVal = 'Prepare: engine';
    case uint16(movementTypes.HANDWORDS_ASK)
        retVal = 'Prepare: ask';
    case uint16(movementTypes.HANDWORDS_DAUGHTER)
        retVal = 'Prepare: daughter';
    case uint16(movementTypes.HANDWORDS_TROUBLE)
        retVal = 'Prepare: trouble';
    case uint16(movementTypes.HANDWORDS_TABLE)
        retVal = 'Prepare: table';
    case uint16(movementTypes.HANDWORDS_SAD)
        retVal = 'Prepare: sad';
    case uint16(movementTypes.HANDWORDS_BUS)
        retVal = 'Prepare: bus';
    case uint16(movementTypes.HANDWORDS_RACE)
        retVal = 'Prepare: race';
    case uint16(movementTypes.HANDWORDS_PUT)
        retVal = 'Prepare: put';
    case uint16(movementTypes.HANDWORDS_CAT)
        retVal = 'Prepare: cat';
    case uint16(movementTypes.HANDWORDS_DRIVE)
        retVal = 'Prepare: drive';
    case uint16(movementTypes.HANDWORDS_THICK)
        retVal = 'Prepare: thick';
    case uint16(movementTypes.HANDWORDS_USUAL)
        retVal = 'Prepare: usual';
    case uint16(movementTypes.HANDWORDS_EARTH)
        retVal = 'Prepare: earth';
    case uint16(movementTypes.HANDWORDS_MAD)
        retVal = 'Prepare: mad';
    case uint16(movementTypes.HANDWORDS_WINDOW)
        retVal = 'Prepare: window';
    case uint16(movementTypes.HANDWORDS_REPLY)
        retVal = 'Prepare: reply';
    case uint16(movementTypes.HANDWORDS_FREE)
        retVal = 'Prepare: free';
    case uint16(movementTypes.HANDWORDS_BUSY)
        retVal = 'Prepare: busy';
    case uint16(movementTypes.HANDWORDS_COUNT)
        retVal = 'Prepare: count';
    case uint16(movementTypes.HANDWORDS_POINT)
        retVal = 'Prepare: point';
    case uint16(movementTypes.HANDWORDS_DANCE)
        retVal = 'Prepare: dance';
    case uint16(movementTypes.HANDWORDS_HANDLE)
        retVal = 'Prepare: handle';
    case uint16(movementTypes.HANDWORDS_COMPUTER)
        retVal = 'Prepare: computer';
    case uint16(movementTypes.HANDWORDS_BORN)
        retVal = 'Prepare: born';
    case uint16(movementTypes.HANDWORDS_DEAL)
        retVal = 'Prepare: deal';
    case uint16(movementTypes.HANDWORDS_THAT)
        retVal = 'Prepare: that';
    case uint16(movementTypes.HANDWORDS_SITUATION)
        retVal = 'Prepare: situation';
    case uint16(movementTypes.HANDWORDS_HALF)
        retVal = 'Prepare: half';
    case uint16(movementTypes.HANDWORDS_NOTHING)
        retVal = 'Prepare: nothing';
    case uint16(movementTypes.HANDWORDS_HIGH)
        retVal = 'Prepare: high';
    case uint16(movementTypes.HANDWORDS_TALL)
        retVal = 'Prepare: tall';
    case uint16(movementTypes.HANDWORDS_FAR)
        retVal = 'Prepare: far';
    case uint16(movementTypes.HANDWORDS_MATTER)
        retVal = 'Prepare: matter';
    case uint16(movementTypes.HANDWORDS_SLEEP)
        retVal = 'Prepare: sleep';
    case uint16(movementTypes.HANDWORDS_ESPECIALLY)
        retVal = 'Prepare: especially';
    case uint16(movementTypes.HANDWORDS_BECAUSE)
        retVal = 'Prepare: because';
    case uint16(movementTypes.HANDWORDS_FINE)
        retVal = 'Prepare: fine';
    case uint16(movementTypes.HANDWORDS_MOVIE)
        retVal = 'Prepare: movie';
    case uint16(movementTypes.HANDWORDS_EXTRA)
        retVal = 'Prepare: extra';
    case uint16(movementTypes.HANDWORDS_RESPONSIBLE)
        retVal = 'Prepare: responsible';
    case uint16(movementTypes.HANDWORDS_HISTORY)
        retVal = 'Prepare: history';
    case uint16(movementTypes.HANDWORDS_DIRTY)
        retVal = 'Prepare: dirty';
    case uint16(movementTypes.HANDWORDS_PERSON)
        retVal = 'Prepare: person';
    case uint16(movementTypes.HANDWORDS_AWAY)
        retVal = 'Prepare: away';
    case uint16(movementTypes.HANDWORDS_VIEW)
        retVal = 'Prepare: view';
    case uint16(movementTypes.HANDWORDS_LIKE)
        retVal = 'Prepare: like';
    case uint16(movementTypes.HANDWORDS_HIT)
        retVal = 'Prepare: hit';
    case uint16(movementTypes.HANDWORDS_CHURCH)
        retVal = 'Prepare: church';
    case uint16(movementTypes.HANDWORDS_VAN)
        retVal = 'Prepare: van';
    case uint16(movementTypes.HANDWORDS_BETWEEN)
        retVal = 'Prepare: between';
    case uint16(movementTypes.HANDWORDS_AMONG)
        retVal = 'Prepare: among';
    case uint16(movementTypes.HANDWORDS_WALL)
        retVal = 'Prepare: wall';
    case uint16(movementTypes.HANDWORDS_MIDDLE)
        retVal = 'Prepare: middle';
    case uint16(movementTypes.HANDWORDS_CARD)
        retVal = 'Prepare: card';
    case uint16(movementTypes.HANDWORDS_WILL)
        retVal = 'Prepare: will';
    case uint16(movementTypes.HANDWORDS_TOMORROW)
        retVal = 'Prepare: tomorrow';
    case uint16(movementTypes.HANDWORDS_FLOWER)
        retVal = 'Prepare: flower';
    case uint16(movementTypes.HANDWORDS_BUSINESS)
        retVal = 'Prepare: business';
    case uint16(movementTypes.HANDWORDS_FAIR)
        retVal = 'Prepare: fair';
    case uint16(movementTypes.HANDWORDS_TODAY)
        retVal = 'Prepare: today';
    case uint16(movementTypes.HANDWORDS_STATION)
        retVal = 'Prepare: station';
    case uint16(movementTypes.HANDWORDS_MUCH)
        retVal = 'Prepare: much';
    case uint16(movementTypes.HANDWORDS_MINUTE)
        retVal = 'Prepare: minute';
    case uint16(movementTypes.HANDWORDS_HE)
        retVal = 'Prepare: he';
    case uint16(movementTypes.HANDWORDS_WASH)
        retVal = 'Prepare: wash';
    case uint16(movementTypes.HANDWORDS_BEYOND)
        retVal = 'Prepare: beyond';
    case uint16(movementTypes.HANDWORDS_NOT)
        retVal = 'Prepare: not';
    case uint16(movementTypes.HANDWORDS_SKIN)
        retVal = 'Prepare: skin';
    case uint16(movementTypes.HANDWORDS_SPACE)
        retVal = 'Prepare: space';
    case uint16(movementTypes.HANDWORDS_WED)
        retVal = 'Prepare: wed';
    case uint16(movementTypes.HANDWORDS_PLACE)
        retVal = 'Prepare: place';
    case uint16(movementTypes.HANDWORDS_THEY)
        retVal = 'Prepare: they';
    case uint16(movementTypes.HANDWORDS_STAR)
        retVal = 'Prepare: star';
    case uint16(movementTypes.HANDWORDS_SLIP)
        retVal = 'Prepare: slip';
    case uint16(movementTypes.HANDWORDS_FIRST)
        retVal = 'Prepare: first';
    case uint16(movementTypes.HANDWORDS_OFFICE)
        retVal = 'Prepare: office';
    case uint16(movementTypes.HANDWORDS_SOON)
        retVal = 'Prepare: soon';
    case uint16(movementTypes.HANDWORDS_SPEND)
        retVal = 'Prepare: spend';
    case uint16(movementTypes.HANDWORDS_LOCK)
        retVal = 'Prepare: lock';
    case uint16(movementTypes.HANDWORDS_POSITION)
        retVal = 'Prepare: position';
    case uint16(movementTypes.HANDWORDS_VERY)
        retVal = 'Prepare: very';
    case uint16(movementTypes.HANDWORDS_BAR)
        retVal = 'Prepare: bar';
    case uint16(movementTypes.HANDWORDS_TONIGHT)
        retVal = 'Prepare: tonight';
    case uint16(movementTypes.HANDWORDS_WHOLE)
        retVal = 'Prepare: whole';
    case uint16(movementTypes.HANDWORDS_ADVERTISE)
        retVal = 'Prepare: advertise';
    case uint16(movementTypes.HANDWORDS_DARK)
        retVal = 'Prepare: dark';
    case uint16(movementTypes.HANDWORDS_PRINCE)
        retVal = 'Prepare: prince';
    case uint16(movementTypes.HANDWORDS_SUDDEN)
        retVal = 'Prepare: sudden';
    case uint16(movementTypes.HANDWORDS_WHO)
        retVal = 'Prepare: who';
    case uint16(movementTypes.HANDWORDS_HAT)
        retVal = 'Prepare: hat';
    case uint16(movementTypes.HANDWORDS_COST)
        retVal = 'Prepare: cost';
    case uint16(movementTypes.HANDWORDS_BOTH)
        retVal = 'Prepare: both';
    case uint16(movementTypes.HANDWORDS_HORSE)
        retVal = 'Prepare: horse';
    case uint16(movementTypes.HANDWORDS_POST)
        retVal = 'Prepare: post';
    case uint16(movementTypes.HANDWORDS_SHOOT)
        retVal = 'Prepare: shoot';
    case uint16(movementTypes.HANDWORDS_COAT)
        retVal = 'Prepare: coat';
    case uint16(movementTypes.HANDWORDS_FRESH)
        retVal = 'Prepare: fresh';
    case uint16(movementTypes.HANDWORDS_PLANT)
        retVal = 'Prepare: plant';
    case uint16(movementTypes.HANDWORDS_BREAK)
        retVal = 'Prepare: break';
    case uint16(movementTypes.HANDWORDS_SAVE)
        retVal = 'Prepare: save';
    case uint16(movementTypes.HANDWORDS_CRIME)
        retVal = 'Prepare: crime';
    case uint16(movementTypes.HANDWORDS_PICK)
        retVal = 'Prepare: pick';
    case uint16(movementTypes.HANDWORDS_CARE)
        retVal = 'Prepare: care';
    case uint16(movementTypes.HANDWORDS_LINE)
        retVal = 'Prepare: line';
    case uint16(movementTypes.HANDWORDS_BIRD)
        retVal = 'Prepare: bird';
    case uint16(movementTypes.HANDWORDS_SHAPE)
        retVal = 'Prepare: shape';
    case uint16(movementTypes.HANDWORDS_TIME)
        retVal = 'Prepare: time';
    case uint16(movementTypes.HANDWORDS_PAY)
        retVal = 'Prepare: pay';
    case uint16(movementTypes.HANDWORDS_EVER)
        retVal = 'Prepare: ever';
    case uint16(movementTypes.HANDWORDS_SCIENCE)
        retVal = 'Prepare: science';
    case uint16(movementTypes.HANDWORDS_STAND)
        retVal = 'Prepare: stand';
    case uint16(movementTypes.HANDWORDS_BALL)
        retVal = 'Prepare: ball';
    case uint16(movementTypes.HANDWORDS_LEAST)
        retVal = 'Prepare: least';
    case uint16(movementTypes.HANDWORDS_AWFUL)
        retVal = 'Prepare: awful';
    case uint16(movementTypes.HANDWORDS_DRY)
        retVal = 'Prepare: dry';
    case uint16(movementTypes.HANDWORDS_SHE)
        retVal = 'Prepare: she';
    case uint16(movementTypes.HANDWORDS_GROW)
        retVal = 'Prepare: grow';
    case uint16(movementTypes.HANDWORDS_TEA)
        retVal = 'Prepare: tea';
    case uint16(movementTypes.HANDWORDS_ALREADY)
        retVal = 'Prepare: already';
    case uint16(movementTypes.HANDWORDS_LAW)
        retVal = 'Prepare: law';
    case uint16(movementTypes.HANDWORDS_SPEAK)
        retVal = 'Prepare: speak';
    case uint16(movementTypes.HANDWORDS_TUESDAY)
        retVal = 'Prepare: tuesday';
    case uint16(movementTypes.HANDWORDS_MAY)
        retVal = 'Prepare: may';
    case uint16(movementTypes.HANDWORDS_BROTHER)
        retVal = 'Prepare: brother';
    case uint16(movementTypes.HANDWORDS_CHAIR)
        retVal = 'Prepare: chair';
    case uint16(movementTypes.HANDWORDS_DANGER)
        retVal = 'Prepare: danger';
    case uint16(movementTypes.HANDWORDS_FEED)
        retVal = 'Prepare: feed';
    case uint16(movementTypes.HANDWORDS_TALK)
        retVal = 'Prepare: talk';
    case uint16(movementTypes.HANDWORDS_NEXT)
        retVal = 'Prepare: next';
    case uint16(movementTypes.HANDWORDS_YOU)
        retVal = 'Prepare: you';
    case uint16(movementTypes.HANDWORDS_ADD)
        retVal = 'Prepare: add';
    case uint16(movementTypes.HANDWORDS_INSIDE)
        retVal = 'Prepare: inside';
    case uint16(movementTypes.HANDWORDS_GOLD)
        retVal = 'Prepare: gold';
    case uint16(movementTypes.HANDWORDS_WRONG)
        retVal = 'Prepare: wrong';
    case uint16(movementTypes.HANDWORDS_SAFE)
        retVal = 'Prepare: safe';
    case uint16(movementTypes.HANDWORDS_PLAN)
        retVal = 'Prepare: plan';
    case uint16(movementTypes.HANDWORDS_HAVE)
        retVal = 'Prepare: have';
    case uint16(movementTypes.HANDWORDS_LAND)
        retVal = 'Prepare: land';
    case uint16(movementTypes.HANDWORDS_BEFORE)
        retVal = 'Prepare: before';
    case uint16(movementTypes.HANDWORDS_CLOSED)
        retVal = 'Prepare: closed';
    case uint16(movementTypes.HANDWORDS_CALL)
        retVal = 'Prepare: call';
    case uint16(movementTypes.HANDWORDS_SPOT)
        retVal = 'Prepare: spot';
    case uint16(movementTypes.HANDWORDS_REPORT)
        retVal = 'Prepare: report';
    case uint16(movementTypes.HANDWORDS_LAST)
        retVal = 'Prepare: last';
    case uint16(movementTypes.HANDWORDS_PUBLIC)
        retVal = 'Prepare: public';
    case uint16(movementTypes.HANDWORDS_WET)
        retVal = 'Prepare: wet';
    case uint16(movementTypes.HANDWORDS_FILM)
        retVal = 'Prepare: film';
    case uint16(movementTypes.HANDWORDS_RED)
        retVal = 'Prepare: red';
    case uint16(movementTypes.HANDWORDS_FORTUNATE)
        retVal = 'Prepare: fortunate';
    case uint16(movementTypes.HANDWORDS_CAKE)
        retVal = 'Prepare: cake';
    case uint16(movementTypes.HANDWORDS_SEND)
        retVal = 'Prepare: send';
    case uint16(movementTypes.HANDWORDS_SHOW)
        retVal = 'Prepare: show';
    case uint16(movementTypes.HANDWORDS_MUST)
        retVal = 'Prepare: must';
    case uint16(movementTypes.HANDWORDS_ALRIGHT)
        retVal = 'Prepare: alright';
    case uint16(movementTypes.HANDWORDS_VIDEO)
        retVal = 'Prepare: video';
    case uint16(movementTypes.HANDWORDS_FIND)
        retVal = 'Prepare: find';
    case uint16(movementTypes.HANDWORDS_REAL)
        retVal = 'Prepare: real';
    case uint16(movementTypes.HANDWORDS_STUDENT)
        retVal = 'Prepare: student';
    case uint16(movementTypes.HANDWORDS_RECENT)
        retVal = 'Prepare: recent';
    case uint16(movementTypes.HANDWORDS_LEG)
        retVal = 'Prepare: leg';
    case uint16(movementTypes.HANDWORDS_FOR)
        retVal = 'Prepare: for';
    case uint16(movementTypes.HANDWORDS_HOME)
        retVal = 'Prepare: home';
    case uint16(movementTypes.HANDWORDS_PLUS)
        retVal = 'Prepare: plus';
    case uint16(movementTypes.HANDWORDS_DOUBT)
        retVal = 'Prepare: doubt';
    case uint16(movementTypes.HANDWORDS_QUESTION)
        retVal = 'Prepare: question';
    case uint16(movementTypes.HANDWORDS_DAY)
        retVal = 'Prepare: day';
    case uint16(movementTypes.HANDWORDS_SLIGHT)
        retVal = 'Prepare: slight';
    case uint16(movementTypes.HANDWORDS_JUDGE)
        retVal = 'Prepare: judge';
    case uint16(movementTypes.HANDWORDS_WE)
        retVal = 'Prepare: we';
    case uint16(movementTypes.HANDWORDS_HAPPY)
        retVal = 'Prepare: happy';
    case uint16(movementTypes.HANDWORDS_SIR)
        retVal = 'Prepare: sir';
    case uint16(movementTypes.HANDWORDS_IMAGINE)
        retVal = 'Prepare: imagine';
    case uint16(movementTypes.HANDWORDS_RIGHT)
        retVal = 'Prepare: right';
    case uint16(movementTypes.HANDWORDS_FIGURE)
        retVal = 'Prepare: figure';
    case uint16(movementTypes.HANDWORDS_YET)
        retVal = 'Prepare: yet';
    case uint16(movementTypes.HANDWORDS_COURT)
        retVal = 'Prepare: court';
    case uint16(movementTypes.HANDWORDS_HEAD)
        retVal = 'Prepare: head';
    case uint16(movementTypes.HANDWORDS_AUNT)
        retVal = 'Prepare: aunt';
    case uint16(movementTypes.HANDWORDS_INTEREST)
        retVal = 'Prepare: interest';
    case uint16(movementTypes.HANDWORDS_GOVERN)
        retVal = 'Prepare: govern';
    case uint16(movementTypes.HANDWORDS_DRUG)
        retVal = 'Prepare: drug';
    case uint16(movementTypes.HANDWORDS_AGAIN)
        retVal = 'Prepare: again';
    case uint16(movementTypes.HANDWORDS_SELL)
        retVal = 'Prepare: sell';
    case uint16(movementTypes.HANDWORDS_PARDON)
        retVal = 'Prepare: pardon';
    case uint16(movementTypes.HANDWORDS_MARK)
        retVal = 'Prepare: mark';
    case uint16(movementTypes.HANDWORDS_HALL)
        retVal = 'Prepare: hall';
    case uint16(movementTypes.HANDWORDS_BENEATH)
        retVal = 'Prepare: beneath';
    case uint16(movementTypes.HANDWORDS_NAUGHTY)
        retVal = 'Prepare: naughty';
    case uint16(movementTypes.HANDWORDS_SOUND)
        retVal = 'Prepare: sound';
    case uint16(movementTypes.HANDWORDS_CHEAP)
        retVal = 'Prepare: cheap';
    case uint16(movementTypes.HANDWORDS_HOT)
        retVal = 'Prepare: hot';
    case uint16(movementTypes.HANDWORDS_SKY)
        retVal = 'Prepare: sky';
    case uint16(movementTypes.HANDWORDS_TWENTY)
        retVal = 'Prepare: twenty';
        
    case uint16(movementTypes.BHANDWORDS_LEFT)
        retVal = 'Prepare: left';
    case uint16(movementTypes.BHANDWORDS_BOOK)
        retVal = 'Prepare: book';
    case uint16(movementTypes.BHANDWORDS_JUST)
        retVal = 'Prepare: just';
    case uint16(movementTypes.BHANDWORDS_QUE)
        retVal = 'Prepare: que';
    case uint16(movementTypes.BHANDWORDS_WHERE)
        retVal = 'Prepare: where';
    case uint16(movementTypes.BHANDWORDS_YOU)
        retVal = 'Prepare: you';
    case uint16(movementTypes.BHANDWORDS_STATES)
        retVal = 'Prepare: states';
    case uint16(movementTypes.BHANDWORDS_FOOD)
        retVal = 'Prepare: food';
    case uint16(movementTypes.BHANDWORDS_XYLOID)
        retVal = 'Prepare: xyloid';
    case uint16(movementTypes.BHANDWORDS_NEWS)
        retVal = 'Prepare: news';
    case uint16(movementTypes.BHANDWORDS_POSTED)
        retVal = 'Prepare: posted';
    case uint16(movementTypes.BHANDWORDS_KNOWS)
        retVal = 'Prepare: knows';
    case uint16(movementTypes.BHANDWORDS_JAVA)
        retVal = 'Prepare: java';
    case uint16(movementTypes.BHANDWORDS_GOOD)
        retVal = 'Prepare: good';
    case uint16(movementTypes.BHANDWORDS_UPON)
        retVal = 'Prepare: upon';
    case uint16(movementTypes.BHANDWORDS_PHONE)
        retVal = 'Prepare: phone';
    case uint16(movementTypes.BHANDWORDS_KANSAS)
        retVal = 'Prepare: kansas';
    case uint16(movementTypes.BHANDWORDS_JERSEY)
        retVal = 'Prepare: jersey';
    case uint16(movementTypes.BHANDWORDS_SEND)
        retVal = 'Prepare: send';
    case uint16(movementTypes.BHANDWORDS_NEW)
        retVal = 'Prepare: new';
    case uint16(movementTypes.BHANDWORDS_BEING)
        retVal = 'Prepare: being';
    case uint16(movementTypes.BHANDWORDS_BIG)
        retVal = 'Prepare: big';
    case uint16(movementTypes.BHANDWORDS_RESEARCH)
        retVal = 'Prepare: research';
    case uint16(movementTypes.BHANDWORDS_CHILDREN)
        retVal = 'Prepare: children';
    case uint16(movementTypes.BHANDWORDS_VOTE)
        retVal = 'Prepare: vote';
    case uint16(movementTypes.BHANDWORDS_BETWEEN)
        retVal = 'Prepare: between';
    case uint16(movementTypes.BHANDWORDS_VIRTUAL)
        retVal = 'Prepare: virtual';
    case uint16(movementTypes.BHANDWORDS_DOWN)
        retVal = 'Prepare: down';
    case uint16(movementTypes.BHANDWORDS_CALL)
        retVal = 'Prepare: call';
    case uint16(movementTypes.BHANDWORDS_THOSE)
        retVal = 'Prepare: those';
    case uint16(movementTypes.BHANDWORDS_USA)
        retVal = 'Prepare: usa';
    case uint16(movementTypes.BHANDWORDS_PAGE)
        retVal = 'Prepare: page';
    case uint16(movementTypes.BHANDWORDS_HAD)
        retVal = 'Prepare: had';
    case uint16(movementTypes.BHANDWORDS_LAW)
        retVal = 'Prepare: law';
    case uint16(movementTypes.BHANDWORDS_VISUAL)
        retVal = 'Prepare: visual';
    case uint16(movementTypes.BHANDWORDS_LINKS)
        retVal = 'Prepare: links';
    case uint16(movementTypes.BHANDWORDS_HISTORY)
        retVal = 'Prepare: history';
    case uint16(movementTypes.BHANDWORDS_URL)
        retVal = 'Prepare: url';
    case uint16(movementTypes.BHANDWORDS_MOST)
        retVal = 'Prepare: most';
    case uint16(movementTypes.BHANDWORDS_DISPLAY)
        retVal = 'Prepare: display';
    case uint16(movementTypes.BHANDWORDS_WAS)
        retVal = 'Prepare: was';
    case uint16(movementTypes.BHANDWORDS_ZAP)
        retVal = 'Prepare: zap';
    case uint16(movementTypes.BHANDWORDS_LAST)
        retVal = 'Prepare: last';
    case uint16(movementTypes.BHANDWORDS_BLACK)
        retVal = 'Prepare: black';
    case uint16(movementTypes.BHANDWORDS_ROOM)
        retVal = 'Prepare: room';
    case uint16(movementTypes.BHANDWORDS_EAST)
        retVal = 'Prepare: east';
    case uint16(movementTypes.BHANDWORDS_CARE)
        retVal = 'Prepare: care';
    case uint16(movementTypes.BHANDWORDS_XANTHIC)
        retVal = 'Prepare: xanthic';
    case uint16(movementTypes.BHANDWORDS_NIGHT)
        retVal = 'Prepare: night';
    case uint16(movementTypes.BHANDWORDS_ISSUES)
        retVal = 'Prepare: issues';
    case uint16(movementTypes.BHANDWORDS_RELATED)
        retVal = 'Prepare: related';
    case uint16(movementTypes.BHANDWORDS_INCLUDES)
        retVal = 'Prepare: includes';
    case uint16(movementTypes.BHANDWORDS_ITEM)
        retVal = 'Prepare: item';
    case uint16(movementTypes.BHANDWORDS_MAP)
        retVal = 'Prepare: map';
    case uint16(movementTypes.BHANDWORDS_ZINC)
        retVal = 'Prepare: zinc';
    case uint16(movementTypes.BHANDWORDS_ZOMBIE)
        retVal = 'Prepare: zombie';
    case uint16(movementTypes.BHANDWORDS_TWO)
        retVal = 'Prepare: two';
    case uint16(movementTypes.BHANDWORDS_ADVANCED)
        retVal = 'Prepare: advanced';
    case uint16(movementTypes.BHANDWORDS_RATE)
        retVal = 'Prepare: rate';
    case uint16(movementTypes.BHANDWORDS_DUE)
        retVal = 'Prepare: due';
    case uint16(movementTypes.BHANDWORDS_PART)
        retVal = 'Prepare: part';
    case uint16(movementTypes.BHANDWORDS_JOIN)
        retVal = 'Prepare: join';
    case uint16(movementTypes.BHANDWORDS_QUIET)
        retVal = 'Prepare: quiet';
    case uint16(movementTypes.BHANDWORDS_KNOWN)
        retVal = 'Prepare: known';
    case uint16(movementTypes.BHANDWORDS_XYLENE)
        retVal = 'Prepare: xylene';
    case uint16(movementTypes.BHANDWORDS_TODAY)
        retVal = 'Prepare: today';
    case uint16(movementTypes.BHANDWORDS_NOT)
        retVal = 'Prepare: not';
    case uint16(movementTypes.BHANDWORDS_JUN)
        retVal = 'Prepare: jun';
    case uint16(movementTypes.BHANDWORDS_MOVIE)
        retVal = 'Prepare: movie';
    case uint16(movementTypes.BHANDWORDS_AUTHOR)
        retVal = 'Prepare: author';
    case uint16(movementTypes.BHANDWORDS_JOINED)
        retVal = 'Prepare: joined';
    case uint16(movementTypes.BHANDWORDS_ZEALOT)
        retVal = 'Prepare: zealot';
    case uint16(movementTypes.BHANDWORDS_HEALTH)
        retVal = 'Prepare: health';
    case uint16(movementTypes.BHANDWORDS_HOURS)
        retVal = 'Prepare: hours';
    case uint16(movementTypes.BHANDWORDS_EASY)
        retVal = 'Prepare: easy';
    case uint16(movementTypes.BHANDWORDS_USERS)
        retVal = 'Prepare: users';
    case uint16(movementTypes.BHANDWORDS_NOV)
        retVal = 'Prepare: nov';
    case uint16(movementTypes.BHANDWORDS_OCTOBER)
        retVal = 'Prepare: october';
    case uint16(movementTypes.BHANDWORDS_OWN)
        retVal = 'Prepare: own';
    case uint16(movementTypes.BHANDWORDS_HOT)
        retVal = 'Prepare: hot';
    case uint16(movementTypes.BHANDWORDS_MAY)
        retVal = 'Prepare: may';
    case uint16(movementTypes.BHANDWORDS_OPTIONS)
        retVal = 'Prepare: options';
    case uint16(movementTypes.BHANDWORDS_REAL)
        retVal = 'Prepare: real';
    case uint16(movementTypes.BHANDWORDS_UPDATED)
        retVal = 'Prepare: updated';
    case uint16(movementTypes.BHANDWORDS_OTHERS)
        retVal = 'Prepare: others';
    case uint16(movementTypes.BHANDWORDS_WHITE)
        retVal = 'Prepare: white';
    case uint16(movementTypes.BHANDWORDS_RED)
        retVal = 'Prepare: red';
    case uint16(movementTypes.BHANDWORDS_FOR)
        retVal = 'Prepare: for';
    case uint16(movementTypes.BHANDWORDS_ROAD)
        retVal = 'Prepare: road';
    case uint16(movementTypes.BHANDWORDS_EDUCATION)
        retVal = 'Prepare: education';
    case uint16(movementTypes.BHANDWORDS_UPDATES)
        retVal = 'Prepare: updates';
    case uint16(movementTypes.BHANDWORDS_REALLY)
        retVal = 'Prepare: really';
    case uint16(movementTypes.BHANDWORDS_XEROSES)
        retVal = 'Prepare: xeroses';
    case uint16(movementTypes.BHANDWORDS_HOTELS)
        retVal = 'Prepare: hotels';
    case uint16(movementTypes.BHANDWORDS_RATES)
        retVal = 'Prepare: rates';
    case uint16(movementTypes.BHANDWORDS_WOMEN)
        retVal = 'Prepare: women';
    case uint16(movementTypes.BHANDWORDS_ISSUE)
        retVal = 'Prepare: issue';
    case uint16(movementTypes.BHANDWORDS_MEMBER)
        retVal = 'Prepare: member';
    case uint16(movementTypes.BHANDWORDS_YEAR)
        retVal = 'Prepare: year';
    case uint16(movementTypes.BHANDWORDS_HELP)
        retVal = 'Prepare: help';
    case uint16(movementTypes.BHANDWORDS_INTO)
        retVal = 'Prepare: into';
    case uint16(movementTypes.BHANDWORDS_ONCE)
        retVal = 'Prepare: once';
    case uint16(movementTypes.BHANDWORDS_GAME)
        retVal = 'Prepare: game';
    case uint16(movementTypes.BHANDWORDS_XYLOL)
        retVal = 'Prepare: xylol';
    case uint16(movementTypes.BHANDWORDS_NONE)
        retVal = 'Prepare: none';
    case uint16(movementTypes.BHANDWORDS_EMAIL)
        retVal = 'Prepare: email';
    case uint16(movementTypes.BHANDWORDS_THEM)
        retVal = 'Prepare: them';
    case uint16(movementTypes.BHANDWORDS_HARD)
        retVal = 'Prepare: hard';
    case uint16(movementTypes.BHANDWORDS_VIDEOS)
        retVal = 'Prepare: videos';
    case uint16(movementTypes.BHANDWORDS_WERE)
        retVal = 'Prepare: were';
    case uint16(movementTypes.BHANDWORDS_QUALIFIED)
        retVal = 'Prepare: qualified';
    case uint16(movementTypes.BHANDWORDS_LIVE)
        retVal = 'Prepare: live';
    case uint16(movementTypes.BHANDWORDS_NOVEMBER)
        retVal = 'Prepare: november';
    case uint16(movementTypes.BHANDWORDS_CHECK)
        retVal = 'Prepare: check';
    case uint16(movementTypes.BHANDWORDS_NEVER)
        retVal = 'Prepare: never';
    case uint16(movementTypes.BHANDWORDS_UNITED)
        retVal = 'Prepare: united';
    case uint16(movementTypes.BHANDWORDS_CONTACT)
        retVal = 'Prepare: contact';
    case uint16(movementTypes.BHANDWORDS_WHY)
        retVal = 'Prepare: why';
    case uint16(movementTypes.BHANDWORDS_LISTING)
        retVal = 'Prepare: listing';
    case uint16(movementTypes.BHANDWORDS_KEYWORDS)
        retVal = 'Prepare: keywords';
    case uint16(movementTypes.BHANDWORDS_WHILE)
        retVal = 'Prepare: while';
    case uint16(movementTypes.BHANDWORDS_UNDER)
        retVal = 'Prepare: under';
    case uint16(movementTypes.BHANDWORDS_TEXT)
        retVal = 'Prepare: text';
    case uint16(movementTypes.BHANDWORDS_DECEMBER)
        retVal = 'Prepare: december';
    case uint16(movementTypes.BHANDWORDS_JACK)
        retVal = 'Prepare: jack';
    case uint16(movementTypes.BHANDWORDS_NOW)
        retVal = 'Prepare: now';
    case uint16(movementTypes.BHANDWORDS_GIVE)
        retVal = 'Prepare: give';
    case uint16(movementTypes.BHANDWORDS_EVEN)
        retVal = 'Prepare: even';
    case uint16(movementTypes.BHANDWORDS_FILES)
        retVal = 'Prepare: files';
    case uint16(movementTypes.BHANDWORDS_NATURAL)
        retVal = 'Prepare: natural';
    case uint16(movementTypes.BHANDWORDS_VOL)
        retVal = 'Prepare: vol';
    case uint16(movementTypes.BHANDWORDS_UNIQUE)
        retVal = 'Prepare: unique';
    case uint16(movementTypes.BHANDWORDS_ZONING)
        retVal = 'Prepare: zoning';
    case uint16(movementTypes.BHANDWORDS_PROJECT)
        retVal = 'Prepare: project';
    case uint16(movementTypes.BHANDWORDS_QUALITY)
        retVal = 'Prepare: quality';
    case uint16(movementTypes.BHANDWORDS_RECENT)
        retVal = 'Prepare: recent';
    case uint16(movementTypes.BHANDWORDS_KENTUCKY)
        retVal = 'Prepare: kentucky';
    case uint16(movementTypes.BHANDWORDS_REPORT)
        retVal = 'Prepare: report';
    case uint16(movementTypes.BHANDWORDS_XERIC)
        retVal = 'Prepare: xeric';
    case uint16(movementTypes.BHANDWORDS_ZEN)
        retVal = 'Prepare: zen';
    case uint16(movementTypes.BHANDWORDS_UNLESS)
        retVal = 'Prepare: unless';
    case uint16(movementTypes.BHANDWORDS_NORTH)
        retVal = 'Prepare: north';
    case uint16(movementTypes.BHANDWORDS_HEAD)
        retVal = 'Prepare: head';
    case uint16(movementTypes.BHANDWORDS_ZEBRA)
        retVal = 'Prepare: zebra';
    case uint16(movementTypes.BHANDWORDS_WILL)
        retVal = 'Prepare: will';
    case uint16(movementTypes.BHANDWORDS_SHOW)
        retVal = 'Prepare: show';
    case uint16(movementTypes.BHANDWORDS_EITHER)
        retVal = 'Prepare: either';
    case uint16(movementTypes.BHANDWORDS_BASED)
        retVal = 'Prepare: based';
    case uint16(movementTypes.BHANDWORDS_HOW)
        retVal = 'Prepare: how';
    case uint16(movementTypes.BHANDWORDS_GENERAL)
        retVal = 'Prepare: general';
    case uint16(movementTypes.BHANDWORDS_MOVIES)
        retVal = 'Prepare: movies';
    case uint16(movementTypes.BHANDWORDS_FOUR)
        retVal = 'Prepare: four';
    case uint16(movementTypes.BHANDWORDS_XYLOPHONE)
        retVal = 'Prepare: xylophone';
    case uint16(movementTypes.BHANDWORDS_YELLOW)
        retVal = 'Prepare: yellow';
    case uint16(movementTypes.BHANDWORDS_XEBEC)
        retVal = 'Prepare: xebec';
    case uint16(movementTypes.BHANDWORDS_GAMES)
        retVal = 'Prepare: games';
    case uint16(movementTypes.BHANDWORDS_FEEDBACK)
        retVal = 'Prepare: feedback';
    case uint16(movementTypes.BHANDWORDS_AMERICAN)
        retVal = 'Prepare: american';
    case uint16(movementTypes.BHANDWORDS_SCHOOL)
        retVal = 'Prepare: school';
    case uint16(movementTypes.BHANDWORDS_SAID)
        retVal = 'Prepare: said';
    case uint16(movementTypes.BHANDWORDS_VALLEY)
        retVal = 'Prepare: valley';
    case uint16(movementTypes.BHANDWORDS_ACCOUNT)
        retVal = 'Prepare: account';
    case uint16(movementTypes.BHANDWORDS_AFTER)
        retVal = 'Prepare: after';
    case uint16(movementTypes.BHANDWORDS_HIS)
        retVal = 'Prepare: his';
    case uint16(movementTypes.BHANDWORDS_DAVID)
        retVal = 'Prepare: david';
    case uint16(movementTypes.BHANDWORDS_MESSAGE)
        retVal = 'Prepare: message';
    case uint16(movementTypes.BHANDWORDS_OLD)
        retVal = 'Prepare: old';
    case uint16(movementTypes.BHANDWORDS_CITY)
        retVal = 'Prepare: city';
    case uint16(movementTypes.BHANDWORDS_XYLAN)
        retVal = 'Prepare: xylan';
    case uint16(movementTypes.BHANDWORDS_BUILDING)
        retVal = 'Prepare: building';
    case uint16(movementTypes.BHANDWORDS_YESTERDAY)
        retVal = 'Prepare: yesterday';
    case uint16(movementTypes.BHANDWORDS_EVERY)
        retVal = 'Prepare: every';
    case uint16(movementTypes.BHANDWORDS_SHE)
        retVal = 'Prepare: she';
    case uint16(movementTypes.BHANDWORDS_THINK)
        retVal = 'Prepare: think';
    case uint16(movementTypes.BHANDWORDS_JOURNAL)
        retVal = 'Prepare: journal';
    case uint16(movementTypes.BHANDWORDS_OUT)
        retVal = 'Prepare: out';
    case uint16(movementTypes.BHANDWORDS_DOES)
        retVal = 'Prepare: does';
    case uint16(movementTypes.BHANDWORDS_DID)
        retVal = 'Prepare: did';
    case uint16(movementTypes.BHANDWORDS_HAVING)
        retVal = 'Prepare: having';
    case uint16(movementTypes.BHANDWORDS_BUSINESS)
        retVal = 'Prepare: business';
    case uint16(movementTypes.BHANDWORDS_WORLD)
        retVal = 'Prepare: world';
    case uint16(movementTypes.BHANDWORDS_PICTURES)
        retVal = 'Prepare: pictures';
    case uint16(movementTypes.BHANDWORDS_ZAMBIA)
        retVal = 'Prepare: zambia';
    case uint16(movementTypes.BHANDWORDS_HAS)
        retVal = 'Prepare: has';
    case uint16(movementTypes.BHANDWORDS_KIT)
        retVal = 'Prepare: kit';
    case uint16(movementTypes.BHANDWORDS_DURING)
        retVal = 'Prepare: during';
    case uint16(movementTypes.BHANDWORDS_THAN)
        retVal = 'Prepare: than';
    case uint16(movementTypes.BHANDWORDS_BUY)
        retVal = 'Prepare: buy';
    case uint16(movementTypes.BHANDWORDS_ARE)
        retVal = 'Prepare: are';
    case uint16(movementTypes.BHANDWORDS_YEARS)
        retVal = 'Prepare: years';
    case uint16(movementTypes.BHANDWORDS_LINK)
        retVal = 'Prepare: link';
    case uint16(movementTypes.BHANDWORDS_BEFORE)
        retVal = 'Prepare: before';
    case uint16(movementTypes.BHANDWORDS_IMAGES)
        retVal = 'Prepare: images';
    case uint16(movementTypes.BHANDWORDS_BECAUSE)
        retVal = 'Prepare: because';
    case uint16(movementTypes.BHANDWORDS_DATE)
        retVal = 'Prepare: date';
    case uint16(movementTypes.BHANDWORDS_JOBS)
        retVal = 'Prepare: jobs';
    case uint16(movementTypes.BHANDWORDS_FULL)
        retVal = 'Prepare: full';
    case uint16(movementTypes.BHANDWORDS_XENOPHOBE)
        retVal = 'Prepare: xenophobe';
    case uint16(movementTypes.BHANDWORDS_QTY)
        retVal = 'Prepare: qty';
    case uint16(movementTypes.BHANDWORDS_INTEREST)
        retVal = 'Prepare: interest';
    case uint16(movementTypes.BHANDWORDS_YEAH)
        retVal = 'Prepare: yeah';
    case uint16(movementTypes.BHANDWORDS_HOUSE)
        retVal = 'Prepare: house';
    case uint16(movementTypes.BHANDWORDS_FEW)
        retVal = 'Prepare: few';
    case uint16(movementTypes.BHANDWORDS_VALUES)
        retVal = 'Prepare: values';
    case uint16(movementTypes.BHANDWORDS_YARDS)
        retVal = 'Prepare: yards';
    case uint16(movementTypes.BHANDWORDS_GOLD)
        retVal = 'Prepare: gold';
    case uint16(movementTypes.BHANDWORDS_KNOWLEDGE)
        retVal = 'Prepare: knowledge';
    case uint16(movementTypes.BHANDWORDS_LIBRARY)
        retVal = 'Prepare: library';
    case uint16(movementTypes.BHANDWORDS_ITEMS)
        retVal = 'Prepare: items';
    case uint16(movementTypes.BHANDWORDS_OFFER)
        retVal = 'Prepare: offer';
    case uint16(movementTypes.BHANDWORDS_FIELD)
        retVal = 'Prepare: field';
    case uint16(movementTypes.BHANDWORDS_AND)
        retVal = 'Prepare: and';
    case uint16(movementTypes.BHANDWORDS_ONLY)
        retVal = 'Prepare: only';
    case uint16(movementTypes.BHANDWORDS_BELOW)
        retVal = 'Prepare: below';
    case uint16(movementTypes.BHANDWORDS_QUANTITY)
        retVal = 'Prepare: quantity';
    case uint16(movementTypes.BHANDWORDS_ALL)
        retVal = 'Prepare: all';
    case uint16(movementTypes.BHANDWORDS_PUBLIC)
        retVal = 'Prepare: public';
    case uint16(movementTypes.BHANDWORDS_TOTAL)
        retVal = 'Prepare: total';
    case uint16(movementTypes.BHANDWORDS_YOURSELF)
        retVal = 'Prepare: yourself';
    case uint16(movementTypes.BHANDWORDS_FILE)
        retVal = 'Prepare: file';
    case uint16(movementTypes.BHANDWORDS_NOTE)
        retVal = 'Prepare: note';
    case uint16(movementTypes.BHANDWORDS_UPDATE)
        retVal = 'Prepare: update';
    case uint16(movementTypes.BHANDWORDS_SUBJECT)
        retVal = 'Prepare: subject';
    case uint16(movementTypes.BHANDWORDS_END)
        retVal = 'Prepare: end';
    case uint16(movementTypes.BHANDWORDS_POSTS)
        retVal = 'Prepare: posts';
    case uint16(movementTypes.BHANDWORDS_THEY)
        retVal = 'Prepare: they';
    case uint16(movementTypes.BHANDWORDS_USER)
        retVal = 'Prepare: user';
    case uint16(movementTypes.BHANDWORDS_EACH)
        retVal = 'Prepare: each';
    case uint16(movementTypes.BHANDWORDS_EBAY)
        retVal = 'Prepare: ebay';
    case uint16(movementTypes.BHANDWORDS_XENIAL)
        retVal = 'Prepare: xenial';
    case uint16(movementTypes.BHANDWORDS_YEA)
        retVal = 'Prepare: yea';
    case uint16(movementTypes.BHANDWORDS_TOP)
        retVal = 'Prepare: top';
    case uint16(movementTypes.BHANDWORDS_COMPUTER)
        retVal = 'Prepare: computer';
    case uint16(movementTypes.BHANDWORDS_OFF)
        retVal = 'Prepare: off';
    case uint16(movementTypes.BHANDWORDS_REPLY)
        retVal = 'Prepare: reply';
    case uint16(movementTypes.BHANDWORDS_DAY)
        retVal = 'Prepare: day';
    case uint16(movementTypes.BHANDWORDS_GIFT)
        retVal = 'Prepare: gift';
    case uint16(movementTypes.BHANDWORDS_THREE)
        retVal = 'Prepare: three';
    case uint16(movementTypes.BHANDWORDS_SERVICE)
        retVal = 'Prepare: service';
    case uint16(movementTypes.BHANDWORDS_QUEST)
        retVal = 'Prepare: quest';
    case uint16(movementTypes.BHANDWORDS_VIEWS)
        retVal = 'Prepare: views';
    case uint16(movementTypes.BHANDWORDS_THERE)
        retVal = 'Prepare: there';
    case uint16(movementTypes.BHANDWORDS_PER)
        retVal = 'Prepare: per';
    case uint16(movementTypes.BHANDWORDS_XANAX)
        retVal = 'Prepare: xanax';
    case uint16(movementTypes.BHANDWORDS_USED)
        retVal = 'Prepare: used';
    case uint16(movementTypes.BHANDWORDS_XRAY)
        retVal = 'Prepare: xray';
    case uint16(movementTypes.BHANDWORDS_YOURS)
        retVal = 'Prepare: yours';
    case uint16(movementTypes.BHANDWORDS_ZEST)
        retVal = 'Prepare: zest';
    case uint16(movementTypes.BHANDWORDS_NUMBER)
        retVal = 'Prepare: number';
    case uint16(movementTypes.BHANDWORDS_WEB)
        retVal = 'Prepare: web';
    case uint16(movementTypes.BHANDWORDS_DEC)
        retVal = 'Prepare: dec';
    case uint16(movementTypes.BHANDWORDS_ZIPLOCK)
        retVal = 'Prepare: ziplock';
    case uint16(movementTypes.BHANDWORDS_YET)
        retVal = 'Prepare: yet';
    case uint16(movementTypes.BHANDWORDS_TRAVEL)
        retVal = 'Prepare: travel';
    case uint16(movementTypes.BHANDWORDS_LEARN)
        retVal = 'Prepare: learn';
    case uint16(movementTypes.BHANDWORDS_WAY)
        retVal = 'Prepare: way';
    case uint16(movementTypes.BHANDWORDS_ADDRESS)
        retVal = 'Prepare: address';
    case uint16(movementTypes.BHANDWORDS_COUNTY)
        retVal = 'Prepare: county';
    case uint16(movementTypes.BHANDWORDS_DATA)
        retVal = 'Prepare: data';
    case uint16(movementTypes.BHANDWORDS_SYSTEM)
        retVal = 'Prepare: system';
    case uint16(movementTypes.BHANDWORDS_KEPT)
        retVal = 'Prepare: kept';
    case uint16(movementTypes.BHANDWORDS_ENERGY)
        retVal = 'Prepare: energy';
    case uint16(movementTypes.BHANDWORDS_HAVE)
        retVal = 'Prepare: have';
    case uint16(movementTypes.BHANDWORDS_ZEPHYR)
        retVal = 'Prepare: zephyr';
    case uint16(movementTypes.BHANDWORDS_ART)
        retVal = 'Prepare: art';
    case uint16(movementTypes.BHANDWORDS_JULY)
        retVal = 'Prepare: july';
    case uint16(movementTypes.BHANDWORDS_JEWELRY)
        retVal = 'Prepare: jewelry';
    case uint16(movementTypes.BHANDWORDS_THAT)
        retVal = 'Prepare: that';
    case uint16(movementTypes.BHANDWORDS_REVIEW)
        retVal = 'Prepare: review';
    case uint16(movementTypes.BHANDWORDS_PROGRAM)
        retVal = 'Prepare: program';
    case uint16(movementTypes.BHANDWORDS_QUEEN)
        retVal = 'Prepare: queen';
    case uint16(movementTypes.BHANDWORDS_NON)
        retVal = 'Prepare: non';
    case uint16(movementTypes.BHANDWORDS_DIFFERENT)
        retVal = 'Prepare: different';
    case uint16(movementTypes.BHANDWORDS_NEXT)
        retVal = 'Prepare: next';
    case uint16(movementTypes.BHANDWORDS_ORDER)
        retVal = 'Prepare: order';
    case uint16(movementTypes.BHANDWORDS_INDEX)
        retVal = 'Prepare: index';
    case uint16(movementTypes.BHANDWORDS_WORK)
        retVal = 'Prepare: work';
    case uint16(movementTypes.BHANDWORDS_HIM)
        retVal = 'Prepare: him';
    case uint16(movementTypes.BHANDWORDS_EVENT)
        retVal = 'Prepare: event';
    case uint16(movementTypes.BHANDWORDS_FINANCIAL)
        retVal = 'Prepare: financial';
    case uint16(movementTypes.BHANDWORDS_CHANGE)
        retVal = 'Prepare: change';
    case uint16(movementTypes.BHANDWORDS_BOX)
        retVal = 'Prepare: box';
    case uint16(movementTypes.BHANDWORDS_DETAILS)
        retVal = 'Prepare: details';
    case uint16(movementTypes.BHANDWORDS_KEYWORD)
        retVal = 'Prepare: keyword';
    case uint16(movementTypes.BHANDWORDS_POST)
        retVal = 'Prepare: post';
    case uint16(movementTypes.BHANDWORDS_BETTER)
        retVal = 'Prepare: better';
    case uint16(movementTypes.BHANDWORDS_VALUE)
        retVal = 'Prepare: value';
    case uint16(movementTypes.BHANDWORDS_CENTER)
        retVal = 'Prepare: center';
    case uint16(movementTypes.BHANDWORDS_HOTEL)
        retVal = 'Prepare: hotel';
    case uint16(movementTypes.BHANDWORDS_XENON)
        retVal = 'Prepare: xenon';
    case uint16(movementTypes.BHANDWORDS_DAYS)
        retVal = 'Prepare: days';
    case uint16(movementTypes.BHANDWORDS_SEE)
        retVal = 'Prepare: see';
    case uint16(movementTypes.BHANDWORDS_HOME)
        retVal = 'Prepare: home';
    case uint16(movementTypes.BHANDWORDS_KOREA)
        retVal = 'Prepare: korea';
    case uint16(movementTypes.BHANDWORDS_EDITION)
        retVal = 'Prepare: edition';
    case uint16(movementTypes.BHANDWORDS_FIND)
        retVal = 'Prepare: find';
    case uint16(movementTypes.BHANDWORDS_YOUTH)
        retVal = 'Prepare: youth';
    case uint16(movementTypes.BHANDWORDS_PHOTO)
        retVal = 'Prepare: photo';
    case uint16(movementTypes.BHANDWORDS_WANT)
        retVal = 'Prepare: want';
    case uint16(movementTypes.BHANDWORDS_QUARTERLY)
        retVal = 'Prepare: quarterly';
    case uint16(movementTypes.BHANDWORDS_OIL)
        retVal = 'Prepare: oil';
    case uint16(movementTypes.BHANDWORDS_LIFE)
        retVal = 'Prepare: life';
    case uint16(movementTypes.BHANDWORDS_ZONE)
        retVal = 'Prepare: zone';
    case uint16(movementTypes.BHANDWORDS_VACATION)
        retVal = 'Prepare: vacation';
    case uint16(movementTypes.BHANDWORDS_ORIGINAL)
        retVal = 'Prepare: original';
    case uint16(movementTypes.BHANDWORDS_USING)
        retVal = 'Prepare: using';
    case uint16(movementTypes.BHANDWORDS_ACCESS)
        retVal = 'Prepare: access';
    case uint16(movementTypes.BHANDWORDS_XEROX)
        retVal = 'Prepare: xerox';
    case uint16(movementTypes.BHANDWORDS_VIDEO)
        retVal = 'Prepare: video';
    case uint16(movementTypes.BHANDWORDS_MAIN)
        retVal = 'Prepare: main';
    case uint16(movementTypes.BHANDWORDS_INFO)
        retVal = 'Prepare: info';
    case uint16(movementTypes.BHANDWORDS_DIRECTOR)
        retVal = 'Prepare: director';
    case uint16(movementTypes.BHANDWORDS_LEVEL)
        retVal = 'Prepare: level';
    case uint16(movementTypes.BHANDWORDS_GREEN)
        retVal = 'Prepare: green';
    case uint16(movementTypes.BHANDWORDS_LOOK)
        retVal = 'Prepare: look';
    case uint16(movementTypes.BHANDWORDS_USR)
        retVal = 'Prepare: usr';
    case uint16(movementTypes.BHANDWORDS_QUIT)
        retVal = 'Prepare: quit';
    case uint16(movementTypes.BHANDWORDS_PLACE)
        retVal = 'Prepare: place';
    case uint16(movementTypes.BHANDWORDS_FORM)
        retVal = 'Prepare: form';
    case uint16(movementTypes.BHANDWORDS_ZODIAC)
        retVal = 'Prepare: zodiac';
    case uint16(movementTypes.BHANDWORDS_REVIEWS)
        retVal = 'Prepare: reviews';
    case uint16(movementTypes.BHANDWORDS_WELL)
        retVal = 'Prepare: well';
    case uint16(movementTypes.BHANDWORDS_CURRENT)
        retVal = 'Prepare: current';
    case uint16(movementTypes.BHANDWORDS_ENTER)
        retVal = 'Prepare: enter';
    case uint16(movementTypes.BHANDWORDS_CODE)
        retVal = 'Prepare: code';
    case uint16(movementTypes.BHANDWORDS_REGISTER)
        retVal = 'Prepare: register';
    case uint16(movementTypes.BHANDWORDS_JAMES)
        retVal = 'Prepare: james';
    case uint16(movementTypes.BHANDWORDS_MODEL)
        retVal = 'Prepare: model';
    case uint16(movementTypes.BHANDWORDS_YORKSHIRE)
        retVal = 'Prepare: yorkshire';
    case uint16(movementTypes.BHANDWORDS_NEED)
        retVal = 'Prepare: need';
    case uint16(movementTypes.BHANDWORDS_HOWEVER)
        retVal = 'Prepare: however';
    case uint16(movementTypes.BHANDWORDS_PRODUCTS)
        retVal = 'Prepare: products';
    case uint16(movementTypes.BHANDWORDS_MARCH)
        retVal = 'Prepare: march';
    case uint16(movementTypes.BHANDWORDS_TIME)
        retVal = 'Prepare: time';
    case uint16(movementTypes.BHANDWORDS_FORUMS)
        retVal = 'Prepare: forums';
    case uint16(movementTypes.BHANDWORDS_MUCH)
        retVal = 'Prepare: much';
    case uint16(movementTypes.BHANDWORDS_SUCH)
        retVal = 'Prepare: such';
    case uint16(movementTypes.BHANDWORDS_YOGA)
        retVal = 'Prepare: yoga';
    case uint16(movementTypes.BHANDWORDS_FORUM)
        retVal = 'Prepare: forum';
    case uint16(movementTypes.BHANDWORDS_HIGH)
        retVal = 'Prepare: high';
    case uint16(movementTypes.BHANDWORDS_POLICY)
        retVal = 'Prepare: policy';
    case uint16(movementTypes.BHANDWORDS_GOT)
        retVal = 'Prepare: got';
    case uint16(movementTypes.BHANDWORDS_OUR)
        retVal = 'Prepare: our';
    case uint16(movementTypes.BHANDWORDS_LIST)
        retVal = 'Prepare: list';
    case uint16(movementTypes.BHANDWORDS_PRICE)
        retVal = 'Prepare: price';
    case uint16(movementTypes.BHANDWORDS_VOLUME)
        retVal = 'Prepare: volume';
    case uint16(movementTypes.BHANDWORDS_OFFICIAL)
        retVal = 'Prepare: official';
    case uint16(movementTypes.BHANDWORDS_KINGDOM)
        retVal = 'Prepare: kingdom';
    case uint16(movementTypes.BHANDWORDS_GARDEN)
        retVal = 'Prepare: garden';
    case uint16(movementTypes.BHANDWORDS_FIRST)
        retVal = 'Prepare: first';
    case uint16(movementTypes.BHANDWORDS_WOULD)
        retVal = 'Prepare: would';
    case uint16(movementTypes.BHANDWORDS_AREA)
        retVal = 'Prepare: area';
    case uint16(movementTypes.BHANDWORDS_ONLINE)
        retVal = 'Prepare: online';
    case uint16(movementTypes.BHANDWORDS_PRICES)
        retVal = 'Prepare: prices';
    case uint16(movementTypes.BHANDWORDS_NEEDS)
        retVal = 'Prepare: needs';
    case uint16(movementTypes.BHANDWORDS_FEATURES)
        retVal = 'Prepare: features';
    case uint16(movementTypes.BHANDWORDS_BROWSE)
        retVal = 'Prepare: browse';
    case uint16(movementTypes.BHANDWORDS_WEBSITE)
        retVal = 'Prepare: website';
    case uint16(movementTypes.BHANDWORDS_RIGHT)
        retVal = 'Prepare: right';
    case uint16(movementTypes.BHANDWORDS_REQUIRED)
        retVal = 'Prepare: required';
    case uint16(movementTypes.BHANDWORDS_RESERVED)
        retVal = 'Prepare: reserved';
    case uint16(movementTypes.BHANDWORDS_WITHOUT)
        retVal = 'Prepare: without';
    case uint16(movementTypes.BHANDWORDS_INCOME)
        retVal = 'Prepare: income';
    case uint16(movementTypes.BHANDWORDS_UNITS)
        retVal = 'Prepare: units';
    case uint16(movementTypes.BHANDWORDS_FAMILY)
        retVal = 'Prepare: family';
    case uint16(movementTypes.BHANDWORDS_OFTEN)
        retVal = 'Prepare: often';
    case uint16(movementTypes.BHANDWORDS_OFFERS)
        retVal = 'Prepare: offers';
    case uint16(movementTypes.BHANDWORDS_GROUPS)
        retVal = 'Prepare: groups';
    case uint16(movementTypes.BHANDWORDS_SUPPORT)
        retVal = 'Prepare: support';
    case uint16(movementTypes.BHANDWORDS_ELSE)
        retVal = 'Prepare: else';
    case uint16(movementTypes.BHANDWORDS_XENOPUS)
        retVal = 'Prepare: xenopus';
    case uint16(movementTypes.BHANDWORDS_INCLUDING)
        retVal = 'Prepare: including';
    case uint16(movementTypes.BHANDWORDS_QUANTUM)
        retVal = 'Prepare: quantum';
    case uint16(movementTypes.BHANDWORDS_QUOTES)
        retVal = 'Prepare: quotes';
    case uint16(movementTypes.BHANDWORDS_HER)
        retVal = 'Prepare: her';
    case uint16(movementTypes.BHANDWORDS_AROUND)
        retVal = 'Prepare: around';
    case uint16(movementTypes.BHANDWORDS_GIVEN)
        retVal = 'Prepare: given';
    case uint16(movementTypes.BHANDWORDS_INTERNET)
        retVal = 'Prepare: internet';
    case uint16(movementTypes.BHANDWORDS_TAKE)
        retVal = 'Prepare: take';
    case uint16(movementTypes.BHANDWORDS_OVER)
        retVal = 'Prepare: over';
    case uint16(movementTypes.BHANDWORDS_GIRLS)
        retVal = 'Prepare: girls';
    case uint16(movementTypes.BHANDWORDS_BEST)
        retVal = 'Prepare: best';
    case uint16(movementTypes.BHANDWORDS_VERY)
        retVal = 'Prepare: very';
    case uint16(movementTypes.BHANDWORDS_JAPANESE)
        retVal = 'Prepare: japanese';
    case uint16(movementTypes.BHANDWORDS_PRIVACY)
        retVal = 'Prepare: privacy';
    case uint16(movementTypes.BHANDWORDS_XIPHOID)
        retVal = 'Prepare: xiphoid';
    case uint16(movementTypes.BHANDWORDS_UNIT)
        retVal = 'Prepare: unit';
    case uint16(movementTypes.BHANDWORDS_COMMENTS)
        retVal = 'Prepare: comments';
    case uint16(movementTypes.BHANDWORDS_INCREASE)
        retVal = 'Prepare: increase';
    case uint16(movementTypes.BHANDWORDS_DVD)
        retVal = 'Prepare: dvd';
    case uint16(movementTypes.BHANDWORDS_NUDE)
        retVal = 'Prepare: nude';
    case uint16(movementTypes.BHANDWORDS_RETURN)
        retVal = 'Prepare: return';
    case uint16(movementTypes.BHANDWORDS_YES)
        retVal = 'Prepare: yes';
    case uint16(movementTypes.BHANDWORDS_FRIEND)
        retVal = 'Prepare: friend';
    case uint16(movementTypes.BHANDWORDS_EDIT)
        retVal = 'Prepare: edit';
    case uint16(movementTypes.BHANDWORDS_THEIR)
        retVal = 'Prepare: their';
    case uint16(movementTypes.BHANDWORDS_BOOKS)
        retVal = 'Prepare: books';
    case uint16(movementTypes.BHANDWORDS_DAILY)
        retVal = 'Prepare: daily';
    case uint16(movementTypes.BHANDWORDS_VERSION)
        retVal = 'Prepare: version';
    case uint16(movementTypes.BHANDWORDS_ZOO)
        retVal = 'Prepare: zoo';
    case uint16(movementTypes.BHANDWORDS_USES)
        retVal = 'Prepare: uses';
    case uint16(movementTypes.BHANDWORDS_SOME)
        retVal = 'Prepare: some';
    case uint16(movementTypes.BHANDWORDS_ANY)
        retVal = 'Prepare: any';
    case uint16(movementTypes.BHANDWORDS_ABOUT)
        retVal = 'Prepare: about';
    case uint16(movementTypes.BHANDWORDS_SHIPPING)
        retVal = 'Prepare: shipping';
    case uint16(movementTypes.BHANDWORDS_ZOLOFT)
        retVal = 'Prepare: zoloft';
    case uint16(movementTypes.BHANDWORDS_UNION)
        retVal = 'Prepare: union';
    case uint16(movementTypes.BHANDWORDS_QUERY)
        retVal = 'Prepare: query';
    case uint16(movementTypes.BHANDWORDS_THE)
        retVal = 'Prepare: the';
    case uint16(movementTypes.BHANDWORDS_IMPORTANT)
        retVal = 'Prepare: important';
    case uint16(movementTypes.BHANDWORDS_THROUGH)
        retVal = 'Prepare: through';
    case uint16(movementTypes.BHANDWORDS_PRODUCT)
        retVal = 'Prepare: product';
    case uint16(movementTypes.BHANDWORDS_BODY)
        retVal = 'Prepare: body';
    case uint16(movementTypes.BHANDWORDS_ARTICLES)
        retVal = 'Prepare: articles';
    case uint16(movementTypes.BHANDWORDS_EARLY)
        retVal = 'Prepare: early';
    case uint16(movementTypes.BHANDWORDS_MAN)
        retVal = 'Prepare: man';
    case uint16(movementTypes.BHANDWORDS_GOD)
        retVal = 'Prepare: god';
    case uint16(movementTypes.BHANDWORDS_XYSTI)
        retVal = 'Prepare: xysti';
    case uint16(movementTypes.BHANDWORDS_INCLUDE)
        retVal = 'Prepare: include';
    case uint16(movementTypes.BHANDWORDS_NATIONAL)
        retVal = 'Prepare: national';
    case uint16(movementTypes.BHANDWORDS_WITH)
        retVal = 'Prepare: with';
    case uint16(movementTypes.BHANDWORDS_YRS)
        retVal = 'Prepare: yrs';
    case uint16(movementTypes.BHANDWORDS_LESS)
        retVal = 'Prepare: less';
    case uint16(movementTypes.BHANDWORDS_JUNE)
        retVal = 'Prepare: june';
    case uint16(movementTypes.BHANDWORDS_AGAIN)
        retVal = 'Prepare: again';
    case uint16(movementTypes.BHANDWORDS_KING)
        retVal = 'Prepare: king';
    case uint16(movementTypes.BHANDWORDS_ZOOM)
        retVal = 'Prepare: zoom';
    case uint16(movementTypes.BHANDWORDS_COMMUNITY)
        retVal = 'Prepare: community';
    case uint16(movementTypes.BHANDWORDS_XYSTER)
        retVal = 'Prepare: xyster';
    case uint16(movementTypes.BHANDWORDS_RATING)
        retVal = 'Prepare: rating';
    case uint16(movementTypes.BHANDWORDS_MANY)
        retVal = 'Prepare: many';
    case uint16(movementTypes.BHANDWORDS_LOCAL)
        retVal = 'Prepare: local';
    case uint16(movementTypes.BHANDWORDS_CLASS)
        retVal = 'Prepare: class';
    case uint16(movementTypes.BHANDWORDS_YOUNGER)
        retVal = 'Prepare: younger';
    case uint16(movementTypes.BHANDWORDS_GROUP)
        retVal = 'Prepare: group';
    case uint16(movementTypes.BHANDWORDS_USE)
        retVal = 'Prepare: use';
    case uint16(movementTypes.BHANDWORDS_YARD)
        retVal = 'Prepare: yard';
    case uint16(movementTypes.BHANDWORDS_TYPE)
        retVal = 'Prepare: type';
    case uint16(movementTypes.BHANDWORDS_NET)
        retVal = 'Prepare: net';
    case uint16(movementTypes.BHANDWORDS_LONG)
        retVal = 'Prepare: long';
    case uint16(movementTypes.BHANDWORDS_JUSTICE)
        retVal = 'Prepare: justice';
    case uint16(movementTypes.BHANDWORDS_RIGHTS)
        retVal = 'Prepare: rights';
    case uint16(movementTypes.BHANDWORDS_FAX)
        retVal = 'Prepare: fax';
    case uint16(movementTypes.BHANDWORDS_YIELD)
        retVal = 'Prepare: yield';
    case uint16(movementTypes.BHANDWORDS_LOOKING)
        retVal = 'Prepare: looking';
    case uint16(movementTypes.BHANDWORDS_JOHNSON)
        retVal = 'Prepare: johnson';
    case uint16(movementTypes.BHANDWORDS_RESOURCES)
        retVal = 'Prepare: resources';
    case uint16(movementTypes.BHANDWORDS_ZENITH)
        retVal = 'Prepare: zenith';
    case uint16(movementTypes.BHANDWORDS_LOW)
        retVal = 'Prepare: low';
    case uint16(movementTypes.BHANDWORDS_COPYRIGHT)
        retVal = 'Prepare: copyright';
    case uint16(movementTypes.BHANDWORDS_KNOW)
        retVal = 'Prepare: know';
    case uint16(movementTypes.BHANDWORDS_PLEASE)
        retVal = 'Prepare: please';
    case uint16(movementTypes.BHANDWORDS_PAGES)
        retVal = 'Prepare: pages';
    case uint16(movementTypes.BHANDWORDS_YOUNG)
        retVal = 'Prepare: young';
    case uint16(movementTypes.BHANDWORDS_AIR)
        retVal = 'Prepare: air';
    case uint16(movementTypes.BHANDWORDS_QUITE)
        retVal = 'Prepare: quite';
    case uint16(movementTypes.BHANDWORDS_XENIA)
        retVal = 'Prepare: xenia';
    case uint16(movementTypes.BHANDWORDS_INDIA)
        retVal = 'Prepare: india';
    case uint16(movementTypes.BHANDWORDS_DESIGN)
        retVal = 'Prepare: design';
    case uint16(movementTypes.BHANDWORDS_FEBRUARY)
        retVal = 'Prepare: february';
    case uint16(movementTypes.BHANDWORDS_XMEN)
        retVal = 'Prepare: xmen';
    case uint16(movementTypes.BHANDWORDS_NAME)
        retVal = 'Prepare: name';
    case uint16(movementTypes.BHANDWORDS_PERSONAL)
        retVal = 'Prepare: personal';
    case uint16(movementTypes.BHANDWORDS_EQUIPMENT)
        retVal = 'Prepare: equipment';
    case uint16(movementTypes.BHANDWORDS_BEEN)
        retVal = 'Prepare: been';
    case uint16(movementTypes.BHANDWORDS_SOFTWARE)
        retVal = 'Prepare: software';
    case uint16(movementTypes.BHANDWORDS_SHOULD)
        retVal = 'Prepare: should';
    case uint16(movementTypes.BHANDWORDS_KIND)
        retVal = 'Prepare: kind';
    case uint16(movementTypes.BHANDWORDS_USB)
        retVal = 'Prepare: usb';
    case uint16(movementTypes.BHANDWORDS_POWER)
        retVal = 'Prepare: power';
    case uint16(movementTypes.BHANDWORDS_OCT)
        retVal = 'Prepare: oct';
    case uint16(movementTypes.BHANDWORDS_DIGITAL)
        retVal = 'Prepare: digital';
    case uint16(movementTypes.BHANDWORDS_XENIC)
        retVal = 'Prepare: xenic';
    case uint16(movementTypes.BHANDWORDS_ACTION)
        retVal = 'Prepare: action';
    case uint16(movementTypes.BHANDWORDS_GETTING)
        retVal = 'Prepare: getting';
    case uint16(movementTypes.BHANDWORDS_EVER)
        retVal = 'Prepare: ever';
    case uint16(movementTypes.BHANDWORDS_BACK)
        retVal = 'Prepare: back';
    case uint16(movementTypes.BHANDWORDS_CAR)
        retVal = 'Prepare: car';
    case uint16(movementTypes.BHANDWORDS_INDUSTRY)
        retVal = 'Prepare: industry';
    case uint16(movementTypes.BHANDWORDS_GLOBAL)
        retVal = 'Prepare: global';
    case uint16(movementTypes.BHANDWORDS_ZIP)
        retVal = 'Prepare: zip';
    case uint16(movementTypes.BHANDWORDS_QUEBEC)
        retVal = 'Prepare: quebec';
    case uint16(movementTypes.BHANDWORDS_VIA)
        retVal = 'Prepare: via';
    case uint16(movementTypes.BHANDWORDS_VARIETY)
        retVal = 'Prepare: variety';
    case uint16(movementTypes.BHANDWORDS_FOUND)
        retVal = 'Prepare: found';
    case uint16(movementTypes.BHANDWORDS_BOTH)
        retVal = 'Prepare: both';
    case uint16(movementTypes.BHANDWORDS_DELIVERY)
        retVal = 'Prepare: delivery';
    case uint16(movementTypes.BHANDWORDS_INSTITUTE)
        retVal = 'Prepare: institute';
    case uint16(movementTypes.BHANDWORDS_GAY)
        retVal = 'Prepare: gay';
    case uint16(movementTypes.BHANDWORDS_VARIOUS)
        retVal = 'Prepare: various';
    case uint16(movementTypes.BHANDWORDS_QUIZ)
        retVal = 'Prepare: quiz';
    case uint16(movementTypes.BHANDWORDS_QUOTED)
        retVal = 'Prepare: quoted';
    case uint16(movementTypes.BHANDWORDS_SPECIAL)
        retVal = 'Prepare: special';
    case uint16(movementTypes.BHANDWORDS_EVENTS)
        retVal = 'Prepare: events';
    case uint16(movementTypes.BHANDWORDS_DIRECTORY)
        retVal = 'Prepare: directory';
    case uint16(movementTypes.BHANDWORDS_UNTIL)
        retVal = 'Prepare: until';
    case uint16(movementTypes.BHANDWORDS_ZYGOTE)
        retVal = 'Prepare: zygote';
    case uint16(movementTypes.BHANDWORDS_QUESTION)
        retVal = 'Prepare: question';
    case uint16(movementTypes.BHANDWORDS_VIEW)
        retVal = 'Prepare: view';
    case uint16(movementTypes.BHANDWORDS_FROM)
        retVal = 'Prepare: from';
    case uint16(movementTypes.BHANDWORDS_FREE)
        retVal = 'Prepare: free';
    case uint16(movementTypes.BHANDWORDS_AVAILABLE)
        retVal = 'Prepare: available';
    case uint16(movementTypes.BHANDWORDS_QUERIES)
        retVal = 'Prepare: queries';
    case uint16(movementTypes.BHANDWORDS_DOWNLOAD)
        retVal = 'Prepare: download';
    case uint16(movementTypes.BHANDWORDS_ESTATE)
        retVal = 'Prepare: estate';
    case uint16(movementTypes.BHANDWORDS_BUT)
        retVal = 'Prepare: but';
    case uint16(movementTypes.BHANDWORDS_KEEPING)
        retVal = 'Prepare: keeping';
    case uint16(movementTypes.BHANDWORDS_KELLY)
        retVal = 'Prepare: kelly';
    case uint16(movementTypes.BHANDWORDS_VIRGINIA)
        retVal = 'Prepare: virginia';
    case uint16(movementTypes.BHANDWORDS_ZEAL)
        retVal = 'Prepare: zeal';
    case uint16(movementTypes.BHANDWORDS_LARGE)
        retVal = 'Prepare: large';
    case uint16(movementTypes.BHANDWORDS_QUESTIONS)
        retVal = 'Prepare: questions';
    case uint16(movementTypes.BHANDWORDS_STATE)
        retVal = 'Prepare: state';
    case uint16(movementTypes.BHANDWORDS_QUOTE)
        retVal = 'Prepare: quote';
    case uint16(movementTypes.BHANDWORDS_GOING)
        retVal = 'Prepare: going';
    case uint16(movementTypes.BHANDWORDS_QUICK)
        retVal = 'Prepare: quick';
    case uint16(movementTypes.BHANDWORDS_NOTICE)
        retVal = 'Prepare: notice';
    case uint16(movementTypes.BHANDWORDS_WHEN)
        retVal = 'Prepare: when';
    case uint16(movementTypes.BHANDWORDS_XYLEM)
        retVal = 'Prepare: xylem';
    case uint16(movementTypes.BHANDWORDS_KITCHEN)
        retVal = 'Prepare: kitchen';
    case uint16(movementTypes.BHANDWORDS_GREAT)
        retVal = 'Prepare: great';
    case uint16(movementTypes.BHANDWORDS_ZERO)
        retVal = 'Prepare: zero';
    case uint16(movementTypes.BHANDWORDS_STORE)
        retVal = 'Prepare: store';
    case uint16(movementTypes.BHANDWORDS_XERUS)
        retVal = 'Prepare: xerus';
    case uint16(movementTypes.BHANDWORDS_JONES)
        retVal = 'Prepare: jones';
    case uint16(movementTypes.BHANDWORDS_HUMAN)
        retVal = 'Prepare: human';
    case uint16(movementTypes.BHANDWORDS_THESE)
        retVal = 'Prepare: these';
    case uint16(movementTypes.BHANDWORDS_WHICH)
        retVal = 'Prepare: which';
    case uint16(movementTypes.BHANDWORDS_JOHN)
        retVal = 'Prepare: john';
    case uint16(movementTypes.BHANDWORDS_MEDIA)
        retVal = 'Prepare: media';
    case uint16(movementTypes.BHANDWORDS_KONG)
        retVal = 'Prepare: kong';
    case uint16(movementTypes.BHANDWORDS_USEFUL)
        retVal = 'Prepare: useful';
    case uint16(movementTypes.BHANDWORDS_RESULTS)
        retVal = 'Prepare: results';
    case uint16(movementTypes.BHANDWORDS_VISIT)
        retVal = 'Prepare: visit';
    case uint16(movementTypes.BHANDWORDS_MUST)
        retVal = 'Prepare: must';
    case uint16(movementTypes.BHANDWORDS_ENGLISH)
        retVal = 'Prepare: english';
    case uint16(movementTypes.BHANDWORDS_ZIPPER)
        retVal = 'Prepare: zipper';
    case uint16(movementTypes.BHANDWORDS_CLICK)
        retVal = 'Prepare: click';
    case uint16(movementTypes.BHANDWORDS_VALID)
        retVal = 'Prepare: valid';
    case uint16(movementTypes.BHANDWORDS_EXAMPLE)
        retVal = 'Prepare: example';
    case uint16(movementTypes.BHANDWORDS_KEY)
        retVal = 'Prepare: key';
    case uint16(movementTypes.BHANDWORDS_GALLERY)
        retVal = 'Prepare: gallery';
    case uint16(movementTypes.BHANDWORDS_QUARTER)
        retVal = 'Prepare: quarter';
    case uint16(movementTypes.BHANDWORDS_JUMP)
        retVal = 'Prepare: jump';
    case uint16(movementTypes.BHANDWORDS_USUALLY)
        retVal = 'Prepare: usually';
    case uint16(movementTypes.BHANDWORDS_HERE)
        retVal = 'Prepare: here';
    case uint16(movementTypes.BHANDWORDS_VOICE)
        retVal = 'Prepare: voice';
    case uint16(movementTypes.BHANDWORDS_TERMS)
        retVal = 'Prepare: terms';
    case uint16(movementTypes.BHANDWORDS_MEMBERS)
        retVal = 'Prepare: members';
    case uint16(movementTypes.BHANDWORDS_WHO)
        retVal = 'Prepare: who';
    case uint16(movementTypes.BHANDWORDS_OPEN)
        retVal = 'Prepare: open';
    case uint16(movementTypes.BHANDWORDS_READ)
        retVal = 'Prepare: read';
    case uint16(movementTypes.BHANDWORDS_JANUARY)
        retVal = 'Prepare: january';
    case uint16(movementTypes.BHANDWORDS_THIS)
        retVal = 'Prepare: this';
    case uint16(movementTypes.BHANDWORDS_KNEW)
        retVal = 'Prepare: knew';
    case uint16(movementTypes.BHANDWORDS_THEN)
        retVal = 'Prepare: then';
    case uint16(movementTypes.BHANDWORDS_GIFTS)
        retVal = 'Prepare: gifts';
    case uint16(movementTypes.BHANDWORDS_ADD)
        retVal = 'Prepare: add';
    case uint16(movementTypes.BHANDWORDS_INSURANCE)
        retVal = 'Prepare: insurance';
    case uint16(movementTypes.BHANDWORDS_KINDS)
        retVal = 'Prepare: kinds';
    case uint16(movementTypes.BHANDWORDS_LOCATION)
        retVal = 'Prepare: location';
    case uint16(movementTypes.BHANDWORDS_WITHIN)
        retVal = 'Prepare: within';
    case uint16(movementTypes.BHANDWORDS_CASE)
        retVal = 'Prepare: case';
    case uint16(movementTypes.BHANDWORDS_ITS)
        retVal = 'Prepare: its';
    case uint16(movementTypes.BHANDWORDS_ONE)
        retVal = 'Prepare: one';
    case uint16(movementTypes.BHANDWORDS_OTHER)
        retVal = 'Prepare: other';
    case uint16(movementTypes.BHANDWORDS_LINE)
        retVal = 'Prepare: line';
    case uint16(movementTypes.BHANDWORDS_OFFICE)
        retVal = 'Prepare: office';
    case uint16(movementTypes.BHANDWORDS_PEOPLE)
        retVal = 'Prepare: people';
    case uint16(movementTypes.BHANDWORDS_MADE)
        retVal = 'Prepare: made';
    case uint16(movementTypes.BHANDWORDS_HAND)
        retVal = 'Prepare: hand';
    case uint16(movementTypes.BHANDWORDS_CONTROL)
        retVal = 'Prepare: control';
    case uint16(movementTypes.BHANDWORDS_MONEY)
        retVal = 'Prepare: money';
    case uint16(movementTypes.BHANDWORDS_SITE)
        retVal = 'Prepare: site';
    case uint16(movementTypes.BHANDWORDS_JAN)
        retVal = 'Prepare: jan';
    case uint16(movementTypes.BHANDWORDS_WATER)
        retVal = 'Prepare: water';
    case uint16(movementTypes.BHANDWORDS_GET)
        retVal = 'Prepare: get';
    case uint16(movementTypes.BHANDWORDS_WHAT)
        retVal = 'Prepare: what';
    case uint16(movementTypes.BHANDWORDS_JUL)
        retVal = 'Prepare: jul';
    case uint16(movementTypes.BHANDWORDS_VAN)
        retVal = 'Prepare: van';
    case uint16(movementTypes.BHANDWORDS_CONTENT)
        retVal = 'Prepare: content';
    case uint16(movementTypes.BHANDWORDS_GUIDE)
        retVal = 'Prepare: guide';
    case uint16(movementTypes.BHANDWORDS_SEX)
        retVal = 'Prepare: sex';
    case uint16(movementTypes.BHANDWORDS_ZIGZAG)
        retVal = 'Prepare: zigzag';
    case uint16(movementTypes.BHANDWORDS_SET)
        retVal = 'Prepare: set';
    case uint16(movementTypes.BHANDWORDS_YORK)
        retVal = 'Prepare: york';
    case uint16(movementTypes.BHANDWORDS_SERVICES)
        retVal = 'Prepare: services';
    case uint16(movementTypes.BHANDWORDS_KIDS)
        retVal = 'Prepare: kids';
    case uint16(movementTypes.BHANDWORDS_ISLAND)
        retVal = 'Prepare: island';
    case uint16(movementTypes.BHANDWORDS_COULD)
        retVal = 'Prepare: could';
    case uint16(movementTypes.BHANDWORDS_ZERG)
        retVal = 'Prepare: zerg';
    case uint16(movementTypes.BHANDWORDS_DRIVE)
        retVal = 'Prepare: drive';
    case uint16(movementTypes.BHANDWORDS_QUICKLY)
        retVal = 'Prepare: quickly';
    case uint16(movementTypes.BHANDWORDS_CAN)
        retVal = 'Prepare: can';
    case uint16(movementTypes.BHANDWORDS_LITTLE)
        retVal = 'Prepare: little';
    case uint16(movementTypes.BHANDWORDS_NETWORK)
        retVal = 'Prepare: network';
    case uint16(movementTypes.BHANDWORDS_BOARD)
        retVal = 'Prepare: board';
    case uint16(movementTypes.BHANDWORDS_VEHICLE)
        retVal = 'Prepare: vehicle';
    case uint16(movementTypes.BHANDWORDS_MEN)
        retVal = 'Prepare: men';
    case uint16(movementTypes.BHANDWORDS_MAIL)
        retVal = 'Prepare: mail';
    case uint16(movementTypes.BHANDWORDS_KEEP)
        retVal = 'Prepare: keep';
    case uint16(movementTypes.BHANDWORDS_COMPANY)
        retVal = 'Prepare: company';
    case uint16(movementTypes.BHANDWORDS_KILL)
        retVal = 'Prepare: kill';
    case uint16(movementTypes.BHANDWORDS_YAHOO)
        retVal = 'Prepare: yahoo';
    case uint16(movementTypes.BHANDWORDS_MAKE)
        retVal = 'Prepare: make';
    case uint16(movementTypes.BHANDWORDS_NEAR)
        retVal = 'Prepare: near';
    case uint16(movementTypes.BHANDWORDS_MARKET)
        retVal = 'Prepare: market';
    case uint16(movementTypes.BHANDWORDS_BLOG)
        retVal = 'Prepare: blog';
    case uint16(movementTypes.BHANDWORDS_INCLUDED)
        retVal = 'Prepare: included';
    case uint16(movementTypes.BHANDWORDS_IMAGE)
        retVal = 'Prepare: image';
    case uint16(movementTypes.BHANDWORDS_ARTICLE)
        retVal = 'Prepare: article';
    case uint16(movementTypes.BHANDWORDS_LOVE)
        retVal = 'Prepare: love';
    case uint16(movementTypes.BHANDWORDS_LIKE)
        retVal = 'Prepare: like';
    case uint16(movementTypes.BHANDWORDS_ANOTHER)
        retVal = 'Prepare: another';
    case uint16(movementTypes.BHANDWORDS_YOUR)
        retVal = 'Prepare: your';
    case uint16(movementTypes.BHANDWORDS_FOLLOWING)
        retVal = 'Prepare: following';
    case uint16(movementTypes.BHANDWORDS_ALSO)
        retVal = 'Prepare: also';
    case uint16(movementTypes.BHANDWORDS_EUROPE)
        retVal = 'Prepare: europe';
    case uint16(movementTypes.BHANDWORDS_JOB)
        retVal = 'Prepare: job';
    case uint16(movementTypes.BHANDWORDS_YAMAHA)
        retVal = 'Prepare: yamaha';
    case uint16(movementTypes.BHANDWORDS_SEARCH)
        retVal = 'Prepare: search';
    case uint16(movementTypes.BHANDWORDS_JAPAN)
        retVal = 'Prepare: japan';
    case uint16(movementTypes.BHANDWORDS_MORE)
        retVal = 'Prepare: more';
    case uint16(movementTypes.BHANDWORDS_MUSIC)
        retVal = 'Prepare: music';

    otherwise
        retVal = char(zeros([1 50]));
end

retVal2(1:length(retVal)) = retVal;
end