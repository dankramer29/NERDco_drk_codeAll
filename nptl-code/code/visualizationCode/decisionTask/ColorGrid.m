
classdef ColorGrid < ScreenObject
    %
    properties
        xc;
        yc;
        
        squareSize;
        
        nSquaresX;
        nSquaresY;
        
        colorAssignment;
        
        colorImage;
        
        colorGreen;
        colorRed;
        
        gridTexture;
        
        nColor0;
        nColor1;
        
        squaresizeInPxforx;
        squaresizeInPxfory;
        
    end
    
    properties(Dependent)
        nSquares;
        
        
    end
    
    methods
        % Constructor
        function ColorGridObj = ColorGrid(xc, yc, squareSize, nSquaresX, nSquaresY, sd)
            
            ColorgridObj.squaresizeInPxforx = 1;
            ColorgridObj.squaresizeInPxfory = 1;
            ColorGridObj.xc = xc;
            ColorGridObj.yc = yc;
            ColorGridObj.squareSize = squareSize;
            ColorGridObj.nSquaresX = nSquaresX;
            ColorGridObj.nSquaresY = nSquaresY;
            ColorGridObj.colorAssignment = NaN*zeros(nSquaresX,nSquaresY);
            ColorGridObj.colorImage = NaN*zeros(ceil(nSquaresX*ColorgridObj.squaresizeInPxforx),ceil(nSquaresY*ColorgridObj.squaresizeInPxfory),4);
            
            ColorGridObj.colorRed = sd.gridisolumred;
            ColorGridObj.colorGreen = sd.gridisolumgreen;
            
        end
        
        function updateProperties(obj, xc, yc, squareSize, nSquaresX, nSquaresY);
            %
            obj.xc = xc;
            obj.yc = yc;
            obj.squareSize = squareSize;
            obj.nSquaresX = nSquaresX;
            obj.nSquaresY = nSquaresY;
            %
        end
        
        function str = describe(obj)
            plusMinus = char(177);
            str = sprintf('ColorGrid at (%g, %g) size %g x %g, %s', ...
                obj.xc, obj.yc, obj.squareSize, obj.nSquaresX, obj.nSquaresY);
        end
        
        function update(r, mgr, sd)
            
        end
        
        function updateColorMatrix(obj,colorMatrix)
            
%             if ~isequal(size(obj.colorAssignment),size(colorMatrix))
%                 fprintf(' Unequal Matrix Sizes! ');
%             end
            assignin('base','colMatrix',colorMatrix);
            obj.colorAssignment = reshape(colorMatrix,obj.nSquaresX,obj.nSquaresY);
            obj.nColor0 = sum(obj.colorAssignment(:) == 0);
            obj.nColor1 = obj.nSquares - obj.nColor0;
        end
        
        function updateColors(obj,colorR,colorG)
            if nargin < 3
                error('Three arguments needed!, object, color 0, color 1)');
            end
            
            obj.colorRed = colorR;
            obj.colorGreen = colorG;
            
        end
        function generateTexture(obj,sd)
            if isnan(obj.colorAssignment(1,1))
                obj.colorAssignment = [zeros(1,obj.nColor0) ones(1,obj.nColor1)];
                obj.colorAssignment = obj.colorAssignment(randperm(obj.nSquares));
                obj.colorAssignment = reshape(obj.colorAssignment, obj.nSquaresX, obj.nSquaresY);
            end
            
            squaresizeInPxforx = 8;
            squaresizeInPxfory = 8;
            
            nSquaresX = ceil(obj.nSquaresX.*squaresizeInPxforx)*1;
            nSquaresY = ceil(obj.nSquaresY.*squaresizeInPxfory)*1;
            
            cntx = 1;
            for xid = 1: squaresizeInPxforx:(nSquaresX - squaresizeInPxforx)+1
                cnty = 1;
                for yid = 1: squaresizeInPxfory :(nSquaresY -  squaresizeInPxfory ) +1
                    if obj.colorAssignment(cntx,cnty) == 0
                        coloridx(1,1,:) = [obj.colorRed 255];  % If the P value is low Most of it is filled with red
                    else
                        coloridx(1,1,:) = [obj.colorGreen 255];  % If the P value is low Most of it is filled with red
                    end
                    obj.colorImage(xid:xid+squaresizeInPxforx-1,yid:yid+squaresizeInPxfory-1,:) = repmat(coloridx,squaresizeInPxforx,squaresizeInPxfory);
                    
                    cnty = cnty + 1;
                end
                cntx = cntx + 1;
            end
            
            Temp(:,:,1) = obj.colorRed(1)*ones(size(obj.colorImage,1)+2,size(obj.colorImage,2)+2);
            Temp(:,:,2) = obj.colorGreen(2)*ones(size(obj.colorImage,1)+2,size(obj.colorImage,2)+2);
            Temp(:,:,3) = 0;
            Temp(:,:,4) = 128;
            
            Temp(2:size(obj.colorImage,1)+1,2:size(obj.colorImage,2)+1,:) = obj.colorImage;
            obj.gridTexture = sd.makeTexture(Temp);
            
            
        end
        
        
        function generate(obj,nColor0,sd)
            if nColor0 > obj.nSquares
                error('Cannot have more squares than in the object!');
            end
            obj.nColor0 = nColor0;
            obj.nColor1 = obj.nSquares - obj.nColor0;
                obj.colorAssignment = [zeros(1,nColor0) ones(1,obj.nColor1)];
                obj.colorAssignment = obj.colorAssignment(randperm(obj.nSquares));
                obj.colorAssignment = reshape(obj.colorAssignment, obj.nSquaresX, obj.nSquaresY);
            
            %              squaresizeInPxforx = obj.squareSize.*sd.nPixelsfor1mmX*1;
            %              squaresizeInPxfory = obj.squareSize.*sd.nPixelsfor1mmY;
            
            
            squaresizeInPxforx = 24;
            squaresizeInPxfory = 24;
            
            nSquaresX = ceil(obj.nSquaresX.*squaresizeInPxforx)*1;
            nSquaresY = ceil(obj.nSquaresY.*squaresizeInPxfory)*1;
            
            %             fprintf('\n %f, %f',nSquaresX,nSquaresY);
            
            
            
            cntx = 1;
            for xid = 1: squaresizeInPxforx:(nSquaresX - squaresizeInPxforx)+1
                cnty = 1;
                for yid = 1: squaresizeInPxfory :(nSquaresY -  squaresizeInPxfory ) +1
                    if obj.colorAssignment(cntx,cnty) == 0
                        coloridx(1,1,:) = [obj.colorRed 255];  % If the P value is low Most of it is filled with red
                    else
                        coloridx(1,1,:) = [obj.colorGreen 255];  % If the P value is low Most of it is filled with red
                    end
                    obj.colorImage(xid:xid+squaresizeInPxforx-1,yid:yid+squaresizeInPxfory-1,:) = repmat(coloridx,squaresizeInPxforx,squaresizeInPxfory);
                    
                    cnty = cnty + 1;
                end
                cntx = cntx + 1;
            end
            
            Temp(:,:,1) = sd.isolumred(1)*ones(size(obj.colorImage,1)+2,size(obj.colorImage,2)+2);
            Temp(:,:,2) = sd.isolumgreen(2)*ones(size(obj.colorImage,1)+2,size(obj.colorImage,2)+2);
            Temp(:,:,3) = 0;
            Temp(:,:,4) = 128;
            
            Temp(2:size(obj.colorImage,1)+1,2:size(obj.colorImage,2)+1,:) = obj.colorImage;
            obj.gridTexture = sd.makeTexture(Temp);
            
        end
        
        function draw(obj, sd)
            if isempty(obj.gridTexture)
                error('Make the texture please!, before drawing');
            end
            xc = obj.xc;
            yc = obj.yc;
            
            squaresizeInPxforx = obj.squareSize.*sd.nPixelsfor1mmX;
            squaresizeInPxfory = obj.squareSize.*sd.nPixelsfor1mmY;
            nPixelsX = obj.nSquaresX.*squaresizeInPxforx;
            nPixelsY = obj.nSquaresY.*squaresizeInPxfory;
            %             fprintf('%f, %f',nPixelsX,nPixelsY);
            
            rect = ceil([sd.toPx(xc) - ceil(nPixelsX/2),...
                sd.toPy(yc) - ceil(nPixelsY/2),...
                sd.toPx(xc) + ceil(nPixelsX/2),...
                sd.toPy(yc) + ceil(nPixelsY/2)]);
            
            
            sd.drawTexture(obj.gridTexture,rect);
            
            % For each xsquare;
            
        end
        
        function nSquares = get.nSquares(obj)
            nSquares = obj.nSquaresX*obj.nSquaresY;
        end
        
        
        
        
        
    end
    
    
    
end




