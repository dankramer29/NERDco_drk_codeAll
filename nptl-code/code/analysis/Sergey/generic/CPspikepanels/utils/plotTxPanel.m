function f=plotTxPanel(data, opts)
% PLOTTXPANEL    
% 
% plotTxPanel(data, opts)


opts.foo = false;
opts = setDefault(opts,'participant','t6');
opts = setDefault(opts,'thresholdMultiplier',-4);
opts = setDefault(opts,'narray',1);
opts = setDefault(opts,'ylim',[-250 250]);
opts = setDefault(opts,'removeCoincident',false);
opts = setDefault(opts,'yscaling',1);
opts = setDefault(opts,'showChannelNums',true);

participant = opts.participant;
threshMult = opts.thresholdMultiplier;
narray = opts.narray;
ylimUV = opts.ylim;
yscaling = opts.yscaling;
remCoinc = opts.removeCoincident;
showChannelNums = opts.showChannelNums;


switch participant
  case 't6'
    [enum, xpos, ypos] = CerebusToCurly(1:96);
  case 's3'
    [enum, xpos, ypos] = CerebusToS3(1:96);
  case 't7'
    [enum, xpos, ypos] = CerebusToT7(1:96, narray);
  case 't5' % Don't have specific map yet, assume same as T7 (which is generic anyway)
    [enum, xpos, ypos] = CerebusToT7(1:96, narray);
  otherwise
    error(['plotTxPanel: dont know this participant: ' participant]);
end


wmin = -5;
wmax = 29;
timeinds = 1:(wmax-wmin+1);

f = figure();
clf;
set(f,'position',[300 300 500 500]);

%set(f,'renderer','painters');
set(f,'renderer','opengl');

set(f, 'visible', 'off');
set(f,'color',0.9 * [1 1 1]);
pause(0.1);

tic;
for nn=1:size(data,1)
    [tmp1, tmp2] = calcThresholdCrossings(data(nn,:),threshMult);
    stc{nn} = tmp2{1};

    spikecounts(nn) = length(stc{nn});
end
t=toc;
disp(sprintf('calculating threshold crossing times took %f seconds',t));

if remCoinc
    numchan = numel(stc);
    allspks=vertcat(stc{:});
    intvl = (wmax-wmin)*2;
    edges = 0:intvl:max(allspks);
    counts=histc(allspks,0:intvl:max(allspks));
    reminds = find(counts/numchan > 0.5);
    disp(sprintf('%g coincident events detected',numel(reminds)));
end

yres = 10;

manualRaster = false;

borderspace= 2;


corners = {[0 0], [0 9], [9 0], [9 9]};

for nc=1:numel(corners)
    axes('position', [corners{nc}(1)/11+1/22, corners{nc}(2)/11+1/22, 1/12, 1/12]);
    h = plot([timeinds(1) timeinds(end) timeinds(end) timeinds(1)], [ylimUV(1) ylimUV(end) ylimUV(1) ylimUV(end)]);
    tmpc = get(f,'color');
    set(h,'color',tmpc);
    makeBlank(gca);

    %% in the lower left corner, plot some axis limits
    if nc==1
        axes('position', [1/22, 1/22, 1/12, 1/12]);
        h = plot([timeinds(1) timeinds(end)], [ylimUV(1) ylimUV(end)]);
        hold on;
        set(gca,'ylim',ylimUV);
        set(gca,'xlim',[0 numel(timeinds)+1]);
        set(h,'visible','off')
        ax(1) = plot(diff(timeinds([1 end]))*0.25+timeinds(1)+[0 0],...
                     [-75 75]);
        ax(2) = plot(diff(timeinds([1 end]))*0.25+timeinds(1)+[0 15],...
                     -75 + [0 0]);
        set(ax,'color',[0 0 0]);
        set(ax,'linewidth',1);
        makeBlank(gca)
    end
end



fprintf('channel   ');
for nch=1:size(data,1)
    fprintf('\b\b%2.0f',nch);
    axes('position', [xpos(nch)/11+1/22, ypos(nch)/11+1/22, 1/12, 1/12]);
    makeBlank(gca);
    ph = [];

    if manualRaster, rasterized = zeros(diff(ylimUV)*yres+1,wmax-wmin+1); end
    set(gca,'ylim',ylimUV);
    set(gca,'xlim',[0 numel(timeinds)+1]);
    if showChannelNums
        th=text(timeinds(end)-10,ylimUV(2)*0.7, sprintf('%2i',nch));
        set(th,'fontsize',8');
        %set(th,'fontname','monospace');
    end

    %if spikecounts(nch) < 10
    %    disp(sprintf('excluding ch %i for lack of spikes', nch));
    %    continue
    %end
    for nspk = 2:length(stc{nch})
        if remCoinc
            if any(abs(stc{nch}(nspk) - (edges(reminds)+intvl/2))<=intvl/2)
                %disp(sprintf('removing from channel %i',nch));
                continue;
            end
        end
        if stc{nch}(nspk) > 1-wmin && stc{nch}(nspk)+wmax < size(data,2) && (stc{nch}(nspk) -  stc{nch}(nspk-1) > 1.5*(wmax-wmin))

            spikewf = data(nch, (wmin:wmax) + stc{nch}(nspk)) * yscaling;
            
            if manualRaster
                remspk = spikewf > ylimUV(2) | spikewf < ylimUV(1);
                timeinds2=timeinds(~remspk);
                spikewf = spikewf(~remspk);
                spikewf = ceil((spikewf - ylimUV(1))*yres);
                inds = sub2ind(size(rasterized),spikewf,timeinds2);
                rasterized(inds) = rasterized(inds)+1;
            else
                %ph(nspk)=plot(data{1}(nch, (wmin:wmax) + stc{nch}(nspk)));
                ph(end+1) = patchline(timeinds, spikewf, 'edgealpha', 0.2, 'edgecolor', 'b');
                hold on;
            end
        end
    end
    if manualRaster
        imagesc(rasterized);
    else
        set(ph,'linewidth',0.5);
    end
end
fprintf('\n');

set(f, 'visible', 'on');
pause(0.1);
