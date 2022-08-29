%%
%connect to optitrack (motive must be running)
fprintf( 'Creating natnet class object\n' )
natnetclient = natnet;

% connect the client to the server (multicast over local loopback) -
% modify for your network
fprintf( 'Connecting to the server\n' )
natnetclient.HostIP = '127.0.0.1';
natnetclient.ClientIP = '127.0.0.1';
natnetclient.ConnectionType = 'Multicast';
natnetclient.connect;
if ( natnetclient.IsConnected == 0 )
    fprintf( 'Client failed to connect\n' )
    fprintf( '\tMake sure the host is connected to the network\n' )
    fprintf( '\tand that the host and client IP addresses are correct\n\n' ) 
    return
end

% get the asset descriptions for the asset names
model = natnetclient.getModelDescription;
if ( model.RigidBodyCount < 1 )
    return
end

%%
disp('---Starting optitrack packet sender---');
keepGoing = true;
socket = InitUDPsender('192.168.30.3',17000,'192.168.30.255',50140);
ss = get(0,'ScreenSize');
ss = ss(3:4);
midPoint(1) = mean([1, ss(1)]);
midPoint(2) = mean([1, ss(2)]);

%%
gainX = 1/0.1; %meters to screen width
gainY = 1/0.1;
global centerRigidBodyPos;
centerRigidBodyPos = [0,0,0];

h_fig = figure;
set(h_fig,'KeyPressFcn',@(src,event)keypresscallback(src,event,natnetclient));

tic;
prevTime = toc;
prevXYZ = [0 0 0];
while keepGoing
    data = natnetclient.getFrame; % method to get current frame
    if (isempty(data.RigidBody(1)))
        fprintf( '\tPacket is empty/stale\n' )
        fprintf( '\tMake sure the server is in Live mode or playing in playback\n\n')
        return
    end
    
    posXYZ = [data.RigidBody(1).x, data.RigidBody(1).y, data.RigidBody(1).z];
    if (any(prevXYZ-posXYZ)~=0) || (toc-prevTime>0.010)
        prevXYZ = posXYZ;
        cPos = posXYZ - centerRigidBodyPos;
        
        xPos = single(cPos(1)*gainX) + 0.5;
        yPos = single(cPos(2)*gainY) + 0.5;
        
        q =  quaternion([data.RigidBody(1).qx, data.RigidBody(1).qy, data.RigidBody(1).qz, data.RigidBody(1).qw]);
        
        prevTime = single(toc);
        packet = [prevTime, xPos, yPos, posXYZ, q.EulerAngles('123')'];
        SendUDP(socket,packet);   
    end
end


    