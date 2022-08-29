function [ending_vectors, avgr] = psphere(starting_vectors, demo)
% PSPHERE Distributes vectors "equally" about a unit sphere.
%
% ENDING_VECTORS, AVGR = PSPHERE(STARTING_VECTORS, DEMO) takes
% as input STARTING_VECTORS, the number of vectors to distribute (if a
% random seed is desired; becomes N), or the actual vectors to use as seed 
% (3 x N, where columns are x, y, and z coordinates and rows are 
% the individual 3-D vectors). If DEMO is non-zero, the movement of the
% points as they are repelling each other is shown graphically as the
% function runs. ENDING_VECTORS is the set of "evenly" 
% distributed unit vectors or points on a unit sphere (see caveats 
% below) and AVGR is the average euclidean distance between the points.
%
% If you request a large number of points, it gets
% slow due to a NxN matrix being formed. You can't specify a
% density, but density*4*pi*R^2 (R=1 in my function) gives the
% approximate number of points to specify.
%
% Distributes N points about a unit sphere so that the straight line
% distance between neighboring points is roughly the same. The
% actual criteria for stopping is slightly different. The difference
% between a given point and every other point is stored in a matrix.
% The iterations stop once the maximum difference between any element
% in successive distance matrices is less than 0.01. An absolute 
% criteria was chosen due to self-distances being 0, and programming 
% around this for relative convergence seemed too much work for too 
% little reward.
%
% The algorithm first generates N random points. Then a repulsive 
% force vector, based on 1/r^2, is calculated for each point due to 
% all of the other points. The resultant force vector for each point
% is normalized, and then each point is displaced a distance S = 1 
% in the direction of the force. Any value of S between 0.0 and 1.0
% seems to work with most values between 0.2 and 1 taking an average 
% of 20 to 30 iterations to converge. If S is too high, too much 
% "energy" is being added to the system and it won't converge. If S is
% too low, the points won't be evenly distributed even though the
% convergence criteria is met. Generally speaking, the larger N is,
% the larger S can be without causing instabilities. After 
% displacement, the point is projected back down onto the unit sphere. 
% When the system nears convergence, the displacement vector for a 
% given point is nearly in the same direction as the radius vector for 
% that point due to the points being equally distributed. A good check 
% to make sure the code is working is to specify N = 4 and then check 
% that the resulting points form a regular tetrahedron (or whatever 
% it's called). How you would do this I don't know (check angles 
% maybe). That's why I supplied the demo option so you could look at 
% it in progress.
%
% Written by Jason Bowman (jbowman90@hotmail.com); last revised by him in
% June 2000. 
% Modified by Beata Jarosiewicz, 2004, to allow option to input a 
% specific set of vectors to use as seed.

if size(starting_vectors) == [1 1];
    start_random = 1;
    n = starting_vectors;
else
    start_random = 0;
    n = length(starting_vectors(:,1));
end

if nargin == 1
  demo = 0;
end

if start_random,
   %Since rand produces number from 0 to 1, subtract off -0.5 so that
   %the points are centered about (0,0,0).
   x = rand(1,n) - 0.5;
   y = rand(1,n) - 0.5;
   z = rand(1,n) - 0.5;
else
   x = starting_vectors(:,1)';
   y = starting_vectors(:,2)';
   z = starting_vectors(:,3)';
end
   
   %Make the matrix R matrices for comparison.
   rm_new = ones(n);
   rm_old = zeros(n);

   %Scale the coordinates so that their distance from the origin is 1.
   r = sqrt(x.^2 + y.^2 + z.^2);

   x = x./r;
   y = y./r;
   z = z./r;

   not_done = 1;

   s = 0.5;

   %Turns off the divide by 0 warning
   warning off

   while not_done

      for i = 1:n

         %Calculate the i,j,k vectors for the direction of the repulsive forces.
         ii = x(i) - x;
         jj = y(i) - y;
         kk = z(i) - z;

         rm_new(i,:) = sqrt(ii.^2 + jj.^2 + kk.^2);

         ii = ii./rm_new(i,:);
         jj = jj./rm_new(i,:);
         kk = kk./rm_new(i,:);

         %Take care of the self terms.
         ii(i) = 0;
         jj(i) = 0;
         kk(i) = 0;

         %Use a 1/r^2 repulsive force, but add 0.01 to the denominator to
         %avoid a 0 * Inf below. The self term automatically disappears since
         %the ii,jj,kk vectors were set to zero for self terms.
         f = 1./(0.01 + rm_new(i,:).^2);

         %Sum the forces.
         fi = sum(f.*ii);
         fj = sum(f.*jj);
         fk = sum(f.*kk);

         %Find magnitude
         fn = sqrt(fi.^2 + fj.^2 + fk.^2);

         %Find the unit direction of repulsion.
         fi = fi/fn;
         fj = fj/fn;
         fk = fk/fn;

         %Step a distance s in the direciton of repulsion
         x(i) = x(i) + s.*fi;
         y(i) = y(i) + s.*fj;
         z(i) = z(i) + s.*fk;

         %Scale the coordinates back down to the unit sphere.
         r = sqrt(x(i).^2 + y(i).^2 + z(i).^2);

         x(i) = x(i)/r;
         y(i) = y(i)/r;
         z(i) = z(i)/r;

      end

      if demo

         figure(10)
         cla
         axis equal

         [xs,ys,zs] = sphere(20);

         h = surf(xs,ys,zs);
         set(h,'Facecolor',[1 0 0])
         l = light;
         lighting phong

         for m = 1:length(x)
             plot3(x(m)*1.01,y(m)*1.01,z(m)*1.01,'.')
             hold on
         end

         axis([-1.2 1.2 -1.2 1.2 -1.2 1.2])

         drawnow

      end

      %Check convergence
      diff = abs(rm_new - rm_old);

      not_done = any(diff(:) > 0.01);

      rm_old = rm_new;

   end %while
   ending_vectors = [x' y' z'];
   

   %Find the smallest distance between neighboring points. To do this
   %exclude the self terms which are 0.
   tmp = rm_new(:);   
   avgr = min(tmp(tmp~=0));

   %Turn back on the default warning state.
   warning backtrace
