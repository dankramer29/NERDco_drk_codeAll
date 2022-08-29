function keypresscallback( src, event, nnc )
    global centerRigidBodyPos;
    if strcmp(event.Key,'f12')
        data = nnc.getFrame;
        centerRigidBodyPos = [data.RigidBody(1).x, data.RigidBody(1).y, data.RigidBody(1).z];
        disp('Recentered');
    end
end

