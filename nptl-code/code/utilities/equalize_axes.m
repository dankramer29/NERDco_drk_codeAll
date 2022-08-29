function equalize_axes(handles,dimension)
% taken from Chethan Pandarinath
  
  if(~exist('dimension','var'))
    dimension = 'all';
  end
  
  if ~length(handles), return; end
  
  set_x = false;
  set_y = false;
  set_z = false;
  
  if(strcmp(dimension,'x'))
    set_x = true;
  elseif (strcmp(dimension,'y'))
    set_y = true;
  elseif (strcmp(dimension,'xy'))
    set_x = true;
    set_y = true;
  elseif (strcmp(dimension,'all'))
    set_x = true;
    set_y = true;
    if length(axis(handles(1)))>4
        set_z = true;
    end
  end

  for a = 1:length(handles)
      dims(a,:) = axis(handles(a));
  end
  
  if(set_x)
    ax(1) = min(dims(:,1));
    ax(2) = max(dims(:,2));
    

    for a = 1:length(handles)
        dimsout = dims(a,:);
        dimsout(1:2) = ax(1:2);
        axis(handles(a),dimsout);
        dims(a,:) = dimsout;
    end
  end
  
  if(set_y)
    ax(3) = min(dims(:,3));
    ax(4) = max(dims(:,4));
    
    for a = 1:length(handles)
        dimsout = dims(a,:);
        dimsout(3:4) = ax(3:4);
        axis(handles(a),dimsout);
        dims(a,:) = dimsout;
    end
  end
  
  if(set_z)
    ax(5) = min(dims(:,5));
    ax(6) = max(dims(:,6));
    
    for a = 1:length(handles)
        dimsout = dims(a,:);
        dimsout(5:6) = ax(5:6);
        axis(handles(a),dimsout);
        dims(a,:) = dimsout;
    end
  end
  
end