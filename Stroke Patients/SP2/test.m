times = zeros(size(GM.values));
for i=1:length(GM.values)-1
    times(i+1) = times(i) + GM.interval; 
end