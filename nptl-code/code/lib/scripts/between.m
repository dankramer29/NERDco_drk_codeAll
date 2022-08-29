function C=between(A,B)
    
    C=A>=B(1) & A<B(2);
    
%     g=find(size(B)==2);
%     if length(g)>1
%         error('more than one size-2 dimension');
%     end
%     h=diff(B,1,g);
%     tmp=B(1)+h/2;
%     C=(A-tmp);