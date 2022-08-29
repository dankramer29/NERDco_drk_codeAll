clear all

remoteIP = '255.255.255.255'; % broadcast to any IP


% remotePort = 5555;          % simulator       % target port, default = 5555 for now
 remotePort = 1002;           % BG2D

% localPort = 5554;            % local port, keep at 5554
fs=30;
n=200;
bin25=zeros(96,fs*n);
im=plot([0 0]);
socket=InitUDPreceiver(remotePort);
while 1
    data=ReceiveUDP(socket,'next');
    if ~isempty(data)   
        x=reshape(data,[length(data)/8 8]);
        disp(x)
        x=x(9:end,:);
        plot(x)
        pause(1)
    end
    
end
i=1;
tix=tic;
spp = 8; %packets per bin
while 1
    
    %     tic
    data=ReceiveUDP(socket,'next');
    % toc
    if length(data) >=100
        k=fs*spp;
        x=reshape(data,[96 k]);
        if exist('t')==1
            t=t+1;
        else
            t=double(x(6,1));
        end
        
%         if x(6,:)==t;
%             bin25(:,(i-1)*k+1:i*k)=x;
%         else
%             continue
%         end
        
        i=i+1;
        if i==n/spp+1
            set(im,'YData',bin25(61,:));
%             %ylim([-150 50])
            xlim([0 n*fs])
            i=1;
            disp([num2str(toc(tix)*1000) '     ' num2str(t)])
            tix=tic;
        end
    else
        %   disp('got a blank')
    end
    
end
CloseUDP(socket);