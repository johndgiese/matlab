function [lambda, Spectra, filenames] = getSpectra(regexp,lambdaRange)
    filenames = dir(regexp);

    temp = csvread(filenames(1).name);
    lambdaAll = temp(:,1);

    if (exist('lambdaRange','var'))
        ind_start = find(lambdaAll > lambdaRange(1),1,'first');
        ind_end = find(lambdaAll > lambdaRange(2),1,'first') - 1; % the -1 makes plots nicer
        lambda = lambdaAll(ind_start:ind_end);
    else
        lambda = lambdaAll;
    end

    Spectra = zeros(length(filenames),length(lambda));

    for k = 1:length(filenames)
        temp = csvread(filenames(k).name);
        Spectra(k,:) = temp(ind_start:ind_end,2);    
    end

end