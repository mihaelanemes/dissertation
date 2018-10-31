function [nR_S1, nR_S2] = trials2counts(stimID, response, rating, nRatings, padCells, padAmount)

% [nR_S1, nR_S2] = trials2counts(stimID, response, rating, nRatings, padCells, padAmount)
%
% Given data from an experiment where an observer discriminates between two
% stimulus alternatives on every trial and provides confidence ratings,
% converts trial by trial experimental information for N trials into response
% counts.
%
% INPUTS
% stimID:   1xN vector. stimID(i) = 0 --> stimulus on i'th trial was S1.
%                       stimID(i) = 1 --> stimulus on i'th trial was S2.
%
% response: 1xN vector. response(i) = 0 --> response on i'th trial was "S1".
%                       response(i) = 1 --> response on i'th trial was "S2".
%
% rating:   1xN vector. rating(i) = X --> rating on i'th trial was X.
%                       X must be in the range 1 <= X <= nRatings.
%
% N.B. all trials where stimID is not 0 or 1, response is not 0 or 1, or
% rating is not in the range [1, nRatings], are omitted from the response
% count.
%
% nRatings: total # of available subjective ratings available for the
%           subject. e.g. if subject can rate confidence on a scale of 1-4,
%           then nRatings = 4
%
% optional inputs
%
% padCells: if set to 1, each response count in the output has the value of
%           padAmount added to it. Padding cells is desirable if trial counts
%           of 0 interfere with model fitting.
%           if set to 0, trial counts are not manipulated and 0s may be
%           present in the response count output.
%           default value for padCells is 0.
%
% padAmount: the value to add to each response count if padCells is set to 1.
%            default value is 1/(2*nRatings)
%
%
% OUTPUTS
% nR_S1, nR_S2
% these are vectors containing the total number of responses in
% each response category, conditional on presentation of S1 and S2.
%
% e.g. if nR_S1 = [100 50 20 10 5 1], then when stimulus S1 was
% presented, the subject had the following response counts:
% responded S1, rating=3 : 100 times
% responded S1, rating=2 : 50 times
% responded S1, rating=1 : 20 times
% responded S2, rating=1 : 10 times
% responded S2, rating=2 : 5 times
% responded S2, rating=3 : 1 time
%
% The ordering of response / rating counts for S2 should be the same as it
% is for S1. e.g. if nR_S2 = [3 7 8 12 27 89], then when stimulus S2 was
% presented, the subject had the following response counts:
% responded S1, rating=3 : 3 times
% responded S1, rating=2 : 7 times
% responded S1, rating=1 : 8 times
% responded S2, rating=1 : 12 times
% responded S2, rating=2 : 27 times
% responded S2, rating=3 : 89 times

% calcualte only for stage 1 using 4 bins

% excluded subj: 1, 8, 33
subjects = [2 3 4 5 6 7 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 ...
    25 26 27 28 29 30 31 32 34];

% saving in a new .mat file
% each row represents one subject

mle = [] ; % save MLE data in this matrix
mle.matrix = zeros (length(subjects), 6);
nRatings = 3;


 for subj = 1:length(subjects)
    file_name = ['DataExp1_Subject',num2str(subjects(subj)),'.mat'];
    load(file_name)
    % load the each subject's data into the vector data matrix
    stimID_be = data.matrix(:,5); % define stimulus (L/R) vector
    response_be = data.matrix(:,8); % define response vector
    rating_be = data.matrix(:,11); % define confidence rating vector
    trial_be = 1:240;
    trial_ae = trial_be';
    
    
    % exclude trials outside 2*SD; calculated for the entire experiment,
    % individually calibrated
    stimID = []; response = []; rating = []; trial = [];
    
    rt = data.matrix(:,10);
    rt_avg  = mean(rt);
    rt_stdinterval = std(rt)*2;
    
    for n = 1:80
        if (rt(n) <= (rt_avg + rt_stdinterval)) && (rt(n) >= (rt_avg - rt_stdinterval))
            stimID = [ stimID; stimID_be(n) ];
            response = [ response; response_be(n) ];
            rating = [ rating; rating_be(n) ];
            trial = [ trial; trial_ae(n) ];
        end
    end
    
    % check for valid inputs
    if ~( length(stimID) == length(response) && length(stimID) == length(rating) )
        error('stimID, response, and rating input vectors must have the same lengths')
    end
    
    % filter bad trials
    f = (stimID == 0 | stimID == 1) & (response == 0 | response == 1) & (rating >= 0.5 & rating <= 1);
    stimID   = stimID(f);
    response = response(f);
    rating   = rating(f);
    
    conf_bin = zeros (length(rating), 1);
    
    for i = 1:length(rating)
        if rating(i) >= 0.5 && rating(i) < 0.67
            conf_bin(i) = 1;
        elseif rating(i) >= 0.67 && rating(i) < 0.83
            conf_bin(i) = 2;
        elseif rating(i) >= 0.83 && rating(i) <= 1
            conf_bin(i) = 3;
%         elseif rating(i) >= 0.875 && rating(i) <= 1
%             conf_bin(i) = 4;
        end
    end
      
% % %     conf_bin = discretize (rating, 4);
% % %     counts_rating = histcounts(conf_bin);
    
    
    % compute response counts
    
    nR_S1 = zeros(1,6);  % S1 responses = targetright = 0
    nR_S2 = zeros(1,6);  % S2 responses = targetleft = 1
    
    
    for t = 1:length(stimID)
        
        % correct responses for S1
        if stimID(t) == 0 && conf_bin(t) == 3 && response(t) == 0
            nR_S1 (1,1) = nR_S1 (1,1) + 1;
        elseif stimID(t) == 0 && conf_bin(t) == 2 && response(t) == 0
            nR_S1 (1,2) = nR_S1 (1,2) + 1;
        elseif stimID(t) == 0 && conf_bin(t) == 1 && response(t) == 0
            nR_S1 (1,3) = nR_S1 (1,3) + 1;
%         elseif stimID(t) == 0 && conf_bin(t) == 1 && response(t) == 0
%             nR_S1 (1,4) = nR_S1 (1,4) + 1;
            
            % incorrect responses for S1
        elseif stimID(t) == 0 && conf_bin(t) == 1 && response(t) == 1
            nR_S1 (1,4) = nR_S1 (1,4) + 1;
        elseif stimID(t) == 0 && conf_bin(t) == 2 && response(t) == 1
            nR_S1 (1,5) = nR_S1 (1,5) + 1;
        elseif stimID(t) == 0 && conf_bin(t) == 3 && response(t) == 1
            nR_S1 (1,6) = nR_S1 (1,6) + 1;
%         elseif stimID(t) == 0 && conf_bin(t) == 4 && response(t) == 1
%             nR_S1 (1,8) = nR_S1 (1,8) + 1;
            
            
            % incorrect response for S2
        elseif stimID(t) == 1 && conf_bin(t) == 3 && response(t) == 0
            nR_S2 (1,1) = nR_S2 (1,1) + 1;
        elseif stimID(t) == 1 && conf_bin(t) == 2 && response(t) == 0
            nR_S2 (1,2) = nR_S2 (1,2) + 1;
        elseif stimID(t) == 1 && conf_bin(t) == 1 && response(t) == 0
            nR_S2 (1,3) = nR_S2 (1,3) + 1;
%         elseif stimID(t) == 1 && conf_bin(t) == 1 && response(t) == 0
%             nR_S2 (1,4) = nR_S2 (1,4) + 1;
            
            % correct response for S2
        elseif stimID(t) == 1 && conf_bin(t) == 1 && response(t) == 1
            nR_S2 (1,4) = nR_S2 (1,4) + 1;
        elseif stimID(t) == 1 && conf_bin(t) == 2 && response(t) == 1
            nR_S2 (1,5) = nR_S2 (1,5) + 1;
        elseif stimID(t) == 1 && conf_bin(t) == 3 && response(t) == 1
            nR_S2 (1,6) = nR_S2 (1,6) + 1;   
%         elseif stimID(t) == 1 && conf_bin(t) == 4 && response(t) == 1
%             nR_S2 (1,8) = nR_S2 (1,8) + 1;
            
        end
    end
    

    fit = fit_meta_d_mcmc(nR_S1, nR_S2)
    
    % saving in a new .mat file
    % each row represents one subject
    
    mle.matrix (subj,1) = fit.d1 ; % saves d'
    mle.matrix (subj,2) = fit.c1 ; % saves no of trials after exclusion of rt outliers
    mle.matrix (subj,3) = fit.meta_d ; % saves meta-d'
    mle.matrix (subj,4) = fit.M_diff ; % saves difference between meta-d' and d'
    mle.matrix (subj,5) = fit.M_ratio ; % saves meta-d'/d'
    mle.matrix (subj,6) = length(stimID);
    % % %     mle.matrix (subj,6) = fit.t2ca_rS1 ; % saves type 1 decision criterion
    % % %     mle.matrix (subj,7) = fit.t2ca_rS2 % saves log likelihood of the data function
    
    
end

% % % save (['M_ratio_estimates'], 'mle');
save (['hmetad_metacog_analogue_3bins_s1'], 'mle');


end