function str = alg2latexNRT(p)
%% Displays the algorithm in LaTeX
% Vadim Bulitko
% Jan 29, 2021

arguments
    p (1,13) double
end

% % Special cases
% if (isequal(algParam,[1 1 0]))
%     % special case: A*
%     str = '\text{A*}';
%     return
% elseif (algParam(1) == 1 && algParam(3) == 0)
%     % special case: wA*
%     str = sprintf('%0.1f\\text{-A*}',algParam(2));
%     return
% end

% General case
%str = sprintf('%0.1f \\cdot g %+0.1f \\cdot h %+0.1f',algParam(1),algParam(2),algParam(3));

%str = num2str(algParam,'%0.2f ');

alpha1 = p(1);
beta1 = p(2);
gamma1 = p(3);

alpha2 = p(4);
beta2 = p(5);
gamma2 = p(6);

alpha3 = p(7);
beta3 = p(8);
gamma3 = p(9);

psi1 = p(10);
phi1 = p(11);

psi2 = p(12);
phi2 = p(13);

if (isnan(alpha2))
    % no cases
    if (beta1 ~= 1 || gamma1 ~= 0)
        % 3-parameter wA*
        str = sprintf('%0.1f \\cdot h %+0.1f \\cdot g %+0.1f',alpha1,beta1,gamma1);
    elseif (alpha1 == 1)
        % just A*
        str = '\text{A*}';
    else
        % classic 1-parameter wA*
        str = sprintf('%0.1f \\cdot h',alpha1);
    end
else
    % cases
    str1 = sprintf('\\begin{cases} %0.1f \\cdot h %+0.1f \\cdot g %+0.1f, & g < %0.1f %+0.1f \\cdot h \\\\',...
        alpha1,beta1,gamma1,psi1,phi1);
    
    str2 = sprintf('%0.1f \\cdot h %+0.1f \\cdot g %+0.1f, & g < %0.1f %+0.1f \\cdot h \\\\',...
        alpha2,beta2,gamma2,psi2,phi2);
    
    str3 = sprintf('%0.1f \\cdot h %+0.1f \\cdot g %+0.1f, & \\text{otherwise} \\end{cases}',...
        alpha3,beta3,gamma3);
    
    str = [str1 str2 str3];
end

end
