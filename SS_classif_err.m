clc; clear; 
xy_train= load('feature_label_train.mat');
xy_val= load('feature_label_val.mat');
for subj= 0:19
    dat.x= [xy_train.feature_label.x(20*subj+1:20*(subj+1), :) ; ...
                xy_val.feature_label.x(20*subj+1:20*(subj+1), :)];
    dat.y= [xy_train.feature_label.y(20*subj+1:20*(subj+1), :) ; ...
                xy_val.feature_label.y(20*subj+1:20*(subj+1), :)];

    g0 = dat.x(dat.y==0,:);
    g1 = dat.x(dat.y==1,:);
    [h,p,ci,stat] = ttest2(g0, g1, 'Vartype', 'unequal');
    % ecdf(p);xlabel('P value'); ylabel('CDF value')

    [~,featureIdxSortbyP] = sort(p,2); % sort the features
    p_sort= sort(p);
    p_thresh= 0.05;
    num_feat= sum(p_sort < p_thresh);
    if num_feat==0 
        num_feat= 1; 
        disp(append('subj', num2str(subj+1),...
                ': lowest p-value = ', num2str(p_sort(1))))
    end
%     disp(append('subj', num2str(subj), '-num_feat: ', num2str(num_feat)))
    disp(num_feat)
%     Taking the features with p-value less than p_thresh and removing the rest
    dat.x = dat.x(:,featureIdxSortbyP(1:num_feat)); 

    rng('default'); rng(14); 

    n_test= 15;
    test_index= randsample(size(dat.x,1), n_test);
    test_dat.x= dat.x(test_index, :); 
    test_dat.y= dat.y(test_index, :);

    train_dat= dat;
    train_dat.x(test_index, :)=[];
    train_dat.y(test_index, :)=[];

    c=3;
    reps= 100; 
    for i =1:reps
        for ii = 1:c
            indx= randsample(size(train_dat.x,1), 5*(ii+1));
            mdllda = fitcdiscr(dat.x(indx,:), dat.y(indx));
            hat_y= mdllda.predict(test_dat.x);
            err_lda(i,ii)= mean(hat_y == test_dat.y);
            clear hat_y

            mdlsvm = fitcsvm(dat.x(indx,:), dat.y(indx), 'KernelFunction', 'rbf');
            hat_y= mdlsvm.predict(test_dat.x);
            err_svmrbf(i,ii)= mean(hat_y == test_dat.y);
            clear hat_y

            mdlcart3 = fitctree(dat.x(indx,:), dat.y(indx), 'MinLeafSize', 2);
            hat_y= mdlcart3.predict(test_dat.x);
            err_cart3(i,ii)= mean(hat_y == test_dat.y);
            clear hat_y

            mdlcart5 = fitctree(dat.x(indx,:), dat.y(indx), 'MinLeafSize', 10);
            hat_y= mdlcart5.predict(test_dat.x);
            err_cart5(i,ii)= mean(hat_y == test_dat.y);
            clear hat_y

            mdl3nn = fitcknn(dat.x(indx,:), dat.y(indx), 'NumNeighbors', 3);
            hat_y= mdl3nn.predict(test_dat.x);
            err_3nn(i,ii)= mean(hat_y == test_dat.y);
            clear hat_y

            mdl5nn = fitcknn(dat.x(indx,:), dat.y(indx), 'NumNeighbors', 5);
            hat_y= mdl5nn.predict(test_dat.x);
            err_5nn(i,ii)= mean(hat_y == test_dat.y);
            clear hat_y

        end
    end
    lda_all_err.(append('subj', num2str(subj+1)))= err_lda;
    svm_all_err.(append('subj', num2str(subj+1)))= err_svmrbf;
    cart3_all_err.(append('subj', num2str(subj+1)))= err_cart3;    
    knn3_all_err.(append('subj', num2str(subj+1)))= err_3nn;
    
    clear err_lda err_svmrbf err_cart3 err_3nn
end

for subj= 1:20
    err_lda_all_mean(subj,:)= mean(lda_all_err.(append('subj', num2str(subj))));
    err_lda_all_std(subj,:)= std(lda_all_err.(append('subj', num2str(subj))));
    
    err_svm_all_mean(subj,:)= mean(svm_all_err.(append('subj', num2str(subj))));
    err_svm_all_std(subj,:)= std(svm_all_err.(append('subj', num2str(subj))));
    
    err_cart3_all_mean(subj,:)= mean(cart3_all_err.(append('subj', num2str(subj))));
    err_cart3_all_std(subj,:)= std(cart3_all_err.(append('subj', num2str(subj))));
    
    err_knn3_all_mean(subj,:)= mean(knn3_all_err.(append('subj', num2str(subj))));
    err_knn3_all_std(subj,:)= std(knn3_all_err.(append('subj', num2str(subj))));
    
end

lda_m= fix(round((err_lda_all_mean),2)*100);
% bb= fix(round((err_lda_all_std),2)*100);
svm_m= fix(round((err_svm_all_mean),2)*100);
cart3_m= fix(round((err_cart3_all_mean),2)*100);
knn3_m= fix(round((err_knn3_all_mean),2)*100);
% all=[lda_m, svm_m, cart3_m, knn3_m]

figure; boxplot(100*err_lda_all_mean); title('LDA'); 
grid on; xticklabels({'10', '15', '20'}); %ylim([50 95]); 

figure; boxplot(100*err_svm_all_mean); title('SVM')
grid on; xticklabels({'10', '15', '20'}); %ylim([50 95]); 

figure; boxplot(err_cart3_all_mean); title('3NN')
grid on; xticklabels({'10', '15', '20'}); %ylim([50 95]); 

% figure; boxplot(err_5nn); title('5NN')
figure; boxplot(err_knn3_all_mean); title('CART-3')
grid on; xticklabels({'10', '15', '20'}); %ylim([50 95]); 


for i=1:3
%     for subj=1:20
%         name= append('subj', num2str(subj));
%         cart3_all_err.(name)
          mean_n= [err_lda_all_mean(:,i) , err_svm_all_mean(:,i), ...
              err_cart3_all_mean(:,i) , err_knn3_all_mean(:,i)]; 
          
          std_n= [err_lda_all_std(:,i) , err_svm_all_std(:,i), ...
              err_cart3_all_std(:,i) , err_knn3_all_std(:,i)]; 
          
          figure; 
          errorbar(mean_n, std_n); 
          legend(['LDA', 'SVM', 'CART', 'k-NN'])
          grid on
%           er = errorbar(x,y,err)
%     end
    
end

%% ----- Barplots -----
b = bar(mean_n, 'grouped');
hold on
nbars = size(mean_n, 2);
x = [];
for i = 1:nbars
    x = [x ; b(i).XEndPoints];
end
errorbar(x',mean_n, std_n,'k','linestyle','none');
hold off

%% ----- Boxplots -----
% % for i =1:reps
% %     for ii = 1:c
% %         indx= randsample(size(train_dat.x,1), ii*50);
% %         mdlsvm = fitcsvm(dat.x(indx,:), dat.y(indx), 'KernelFunction', 'rbf');
% %         hat_y= mdlsvm.predict(test_dat.x);
% %         err_svmrbf(i,ii)= mean(hat_y ~= test_dat.y);
% %     end
% % end
% % % figure; boxplot(err_svmrbf); title('RBF SVM')
% %  
% % rms_svmrbf= sqrt(mean(err_svmrbf).^2 + var(err_svmrbf));
% % % figure;plot(rms_svmrbf, 'marker', 'o'); title ('RBF-SVM')
% % 
% % 
% % for i =1:reps
% %     for ii = 1:c
% %         indx= randsample(size(train_dat.x,1), ii*50);
% %         mdlcart3 = fitctree(dat.x(indx,:), dat.y(indx), 'MinLeafSize', 2);
% %         hat_y= mdlcart3.predict(test_dat.x);
% %         err_cart3(i,ii)= mean(hat_y ~= test_dat.y);
% %     end
% % end
% % rms_svmrbf= sqrt(mean(err_svmrbf).^2 + var(err_svmrbf));
% % rms_cart3= sqrt(mean(err_cart3).^2 + var(err_cart3));
% % 
% % for i =1:reps
% %     for ii = 1:c
% %         indx= randsample(size(train_dat.x,1), ii*50);
% %         mdlcart5 = fitctree(dat.x(indx,:), dat.y(indx), 'MinLeafSize', 10);
% %         hat_y= mdlcart5.predict(test_dat.x);
% %         err_cart5(i,ii)= mean(hat_y ~= test_dat.y);
% %     end
% % end
% % % figure; boxplot(err_cart); title('CART')
% % rms_svmrbf= sqrt(mean(err_svmrbf).^2 + var(err_svmrbf));
% % rms_cart3= sqrt(mean(err_cart3).^2 + var(err_cart3));
% % rms_cart5= sqrt(mean(err_cart5).^2 + var(err_cart5));
% % % figure;plot(rms_cart, 'marker', 'o', 'title', 'CART')
% % 
% % for i =1:reps
% %     for ii = 1:c
% %         indx= randsample(size(train_dat.x,1), ii*50);
% %         mdl3nn = fitcknn(dat.x(indx,:), dat.y(indx), 'NumNeighbors', 3);
% %         hat_y= mdl3nn.predict(test_dat.x);
% %         err_3nn(i,ii)= mean(hat_y ~= test_dat.y);
% %     end
% % end
% % % figure; boxplot(err_3nn); title('3NN')
% % rms_svmrbf= sqrt(mean(err_svmrbf).^2 + var(err_svmrbf));
% % rms_cart3= sqrt(mean(err_cart3).^2 + var(err_cart3));
% % rms_cart5= sqrt(mean(err_cart5).^2 + var(err_cart5)); 
% % rms_3nn= sqrt(mean(err_3nn).^2 + var(err_3nn));
% % 
% % %%5nn
% % for i =1:reps
% %     for ii = 1:c
% %         indx= randsample(size(train_dat.x,1), ii*50);
% %         mdl5nn = fitcknn(dat.x(indx,:), dat.y(indx), 'NumNeighbors', 5);
% %         hat_y= mdl5nn.predict(test_dat.x);
% %         err_5nn(i,ii)= mean(hat_y ~= test_dat.y);
% %     end
% % end
% % % figure; boxplot(err_5nn); title('5NN')
% % 
% % 
% % rms_svmrbf= sqrt(mean(err_svmrbf).^2 + var(err_svmrbf));
% % rms_cart3= sqrt(mean(err_cart3).^2 + var(err_cart3));
% % rms_cart5= sqrt(mean(err_cart5).^2 + var(err_cart5)); 
% % rms_3nn= sqrt(mean(err_3nn).^2 + var(err_3nn)); 
% % rms_5nn= sqrt(mean(err_5nn).^2 + var(err_5nn));
% % 
% % t= 1:c;
% % figure; plot(t,rms_lda, ...
% %      t, rms_svmrbf, ...
% %     t, rms_cart3, t, rms_cart5, ...
% %     t, rms_3nn, t, rms_5nn); 
% % legend('LDA', 'RBF SVM', 'CART-MLS3', 'CART-MLS10', '3NN', '5NN') 
% % grid on         
% % 
% % %% 
% % 
% % % n50_errors= [err_lda(:,1), err_svmrbf(:,1), err_3nn(:,1), err_5nn(:,1), err_cart(:,1)]
% % 
% % for i=1:5
% %     figure;
% %     boxplot([err_lda(:,i), err_svmrbf(:,i), ...
% %         err_3nn(:,i), err_5nn(:,i), ...
% %         err_cart3(:,i), err_cart5(:,i)])
% %     title('n', num2str(i))
% % end

