%% WORD ERROR RATE
% |Word error rate| (WER) is a measure (metric) of the performance  
% of an automatic speech recognition, machine translation etc.

%% Description
% The function is intended for calculation of WER between word
%  sequence _H_ (hypothesis) and word sequence _R_ (reference).
%
% For calculation we use Levenshtein distance on word level.
% Levenshtein distance is a minimal quantity of insertions,
% deletions and substitutions of words for conversion of a hypothesis to 
% a reference.
%%
%
% $$ WER = \frac{D(H,R)}{N} $$
%
% where _D(H,R)_ is a Levenshtein distance between _H_ and _R_, and _N_ is
% the number of words in the reference _R_.
% _H_ and _R_ are cell arrays of words (for example after using TEXTSCAN)
% or cells with word sequences or strings. Types of _H_ and _R_ may be
% different.


%% Usage
% |W = WER(H,R)| returns array W. 
%
% * W(1) is WER for case sensitive.
% * W(2) is WER for case insensitive.
% 
% |W = WER(H,R,1)| and both _H_ and _R_ are strings then we calculate  
% distances on character level and result is the character error rate (CHR).
%
%% Examples
%%
% 
%%
% 
% * |1. Cell arrays of words|
h=[{'The'},{'carpenter'},{'said'},{'that'},{'average'},{'well'},...
  {'is'},{'concealing'},{'a'},{'lot'},{'of'},{'variance'}];
r=[{'Then'},{'Carpenter'},{'said'},{'that'},{'average'},{'value'},...
  {'is'},{'concealing'},{'a'},{'lot'},{'of'},{'variances'}];
w=WER(h,r);
disp('WER, case sensitive');disp(w(1))
disp('WER, case insensitive');disp(w(2))
%%
% 
% * |2. Cells with word sequences|
h={'The','English','word','probability','derives',...
   'from','Latin','word','probitas'};
r={'The','English','word','Probability','derives',...
   'from','the','Latinic','word','Probabilitas'};
w=WER(h,r);
disp('WER, case sensitive');disp(w(1))
disp('WER, case insensitive');disp(w(2))
%%
% 
% * |3. Strings|
h='Mathworks connection programs';
r='MathWorks Connections Program';
w=WER(h,r);
disp('WER, case sensitive');disp(w(1))
disp('WER, case insensitive');disp(w(2))
w=WER(h,r,1);
disp('CHR, case sensitive');disp(w(1))
disp('CHR, case insensitive');disp(w(2))





