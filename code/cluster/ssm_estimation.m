function netest = ssm_estimation(option, z, P, P_a, X, inp, S, G)

    noisevar_eps = 1e-5;
    
     %% compute all expectancy sums across trials & time points

    xEz = X(:, option.nonNaNidx) * z(:, option.nonNaNidx)'; %t=1:T x(k)E[z(k)]^T
    xx = X(:, option.nonNaNidx) * X(:, option.nonNaNidx)'; %t=1:T x(k)x(k)^T
    Ezz_1totau = sum(P(:, :, option.nonNaNidx), 3); % T = 1:T E[z(t)z(t)']

    Ez_2toT = sum(z(:, 2:end), 2); %t=2:T E[z(t)]
    Ez_1_2toT = sum(z(:, 1:end - 1), 2); %t=2:T E[z(t-1)]

    inpEz = inp * z'; %t=1:T s(k)E[z(k)]^T
    inpEz_1 = inp(:, 2:end) * z(:, 1:end-1)'; %t=2:T s(k)E[z(k-1)]^T
    iinp_1toT = sum(inp, 2); %t=1:T s(k)
    iinp_2toT = sum(inp(:, 2:end), 2); %t=2:T s(k)
    inpinp = inp * inp';
    
    Ezz_1toT = sum(P, 3); % T = 1:T E[z(t)z(t)']
    Ezz_2toT = sum(P(:, :, 2:end), 3); % T = 2:T E[z(t)z(t)']
    Ez_1z_1_2toT = sum(P(:, :, 1:end-1), 3); % T = 2:T E[z(t-1)z(t-1)']
    Ezz_1_2toT = sum(P_a(:, :, 2:end) ,3); % E[z(t)z(t-1)']
    
    %% solve for parameters G of observation model
%     B = xEz / Ezz_1toT; % if B is not identity
    B = eye(option.dimX);
    if isempty(G)
        G = diag(max(diag(xx - xEz * B' - B * xEz' + B * Ezz_1totau * B') ...
                     ./ (option.tau), noisevar_eps));% assumes G to be diag
    end

    
 %% latent parameter estimates
    if option.input
        EL = [Ez_1z_1_2toT, Ez_1_2toT, inpEz_1'; Ez_1_2toT', (option.T-1), ...
            iinp_2toT'; inpEz_1, iinp_2toT, inpinp];
        ER = [Ezz_1_2toT, Ez_2toT, inpEz'];

        AWhC = ER / EL;
        A = AWhC([1:option.dimZ], [1:option.dimZ]);
        h = AWhC(:, option.dimZ+1);
        C = AWhC(:, option.dimZ+2:end); 
    else
       EL = [Ez_1z_1_2toT, Ez_1_2toT; Ez_1_2toT', (option.T-1)];
        ER = [Ezz_1_2toT, Ez_2toT];

        AWhC = ER / EL;
        A = AWhC([1:option.dimZ], [1:option.dimZ]);
        h = AWhC(:, option.dimZ+1);
        C = zeros(option.dimZ, option.dimInp); 
    end
    
    mu0 = (z(:,1)- C * inp(:,1));
    
    if isempty(S)
        S = diag(max(diag(Ezz_1toT - mu0 * z(:, 1)' - z(:, 1) * mu0' + ...
                mu0 * mu0' + mu0 * inp(:, 1)' * C' + C * inp(:, 1) * mu0' ...
                - inpEz' * C' - C * inpEz + C * inpinp * C' ...
                - A * Ezz_1_2toT' - Ezz_1_2toT * A' + A * Ez_1z_1_2toT * A' ...
                - Ez_2toT * h' - h * Ez_2toT' + (option.T - 1) * h * h' + ...
                + h * Ez_1_2toT' * A' + A * Ez_1_2toT * h' ...
                + A * inpEz_1' * C' + C * inpEz_1 * A' + h * iinp_2toT' * C' ...
                + C * iinp_2toT * h') ./ option.T, noisevar_eps));
    end
    
    netest.G=G; netest.B=B; netest.A=diag(diag(A)); netest.W=A-diag(diag(A)); 
    netest.h=h; netest.C=C; netest.mu0=mu0; netest.S = S;
end
