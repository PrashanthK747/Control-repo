%% ------------------------- Drone Parameters --------------------------
gravity = 9.81;
mass = 100;
moment_arm = 0.05;
max_thrust = 1.2*mass*gravity;
min_thrust = 0;
%% ------------------------- Simulation Initialization --------------------------
flightTime = 4;
tstart = 0;             % simulation start time
tend = flightTime;      % simulation end time
tstep = 0.01;           % simulation time step
% condition to save the animation
video_on = false;
%% ------------------------- Control Parameters --------------------------
des_height = 8;
des_vel = 0;
ts = 0.6; % settling time
zeta = 1; % critically damped system

% Gains calculated using pole placement law
wn = 4/(zeta*ts);
Kp = wn^2;
Kd = 2*zeta*wn;

%% ------------------------- INITIAL CONDITIONS --------------------------
ini_pos = 0;            % initial position
ini_vel = 0;            % initial velocity
z_ini = [ini_pos;ini_vel];
n_iter = tend/tstep;    % number of iterations
t = tstart;

%% ------------------------- Matrix Initialization --------------------------
control_force = zeros(n_iter+1,1);
a = zeros(n_iter+1,1);
v = zeros(n_iter+1,1);
h = zeros(n_iter+1,1);
tsave = zeros(n_iter+1,1);
u = zeros(n_iter+1,1);
%% ------------------------- Figure Initialization --------------------------

video_write = VideoWriter('drone_video.mp4','MPEG-4');
if video_on
    open(video_write);
end
fig1 = figure;
sz = [1000 600]; % figure size
screensize = get(0,'ScreenSize');
xpos = ceil((screensize(3)-sz(1))/2); % center the figure on the screen horizontally
ypos = ceil((screensize(4)-sz(2))/2); % center the figure on the screen vertically
set(fig1, 'Position', [xpos ypos sz])
%
height2d = subplot(2,2,[1,3]);
% Desired Height Line plot
plot(height2d,[-1,1],[des_height,des_height],'--black')
hold on
hplot = plot(height2d,0,ini_pos,'ob','MarkerSize', 5);
hold on
m_plot = plot(height2d,0,0,'black','Linewidth',1.5,'MarkerSize', 10);
xlabel('x [m]'); ylabel('z [m]');
ylim(height2d,[0 10])
xlim(height2d,[-1 1])
hold on
grid on
%
tstep2d = subplot(2,2,2);
tplot = plot(tstep2d,t,ini_pos,'-','MarkerSize', 5);
xlabel('t [s]'); ylabel('z [m]');
ylim(tstep2d,[0 10]);
xlim(tstep2d,[0 flightTime]);
hold on;
grid on;
%
u2d = subplot(2,2,4);
uplot = plot(u2d,t,0,'-','MarkerSize', 5);
xlim(u2d,[0 flightTime]);
xlabel('t [s]'); ylabel('Control Force [N]');
hold on;
grid on;

%% ------------------------- Main Program --------------------------

for i=1:n_iter+1
    if i == 1
        act_height = ini_pos;
        act_vel = ini_vel;
        control_force(i,1) = 0;
        v(i,1) = ini_vel;
        h(i,1) = ini_pos;
        tsave(i,1) = tstart;
        
        % Title Initialization
        ttitle = title(tstep2d, sprintf('iteration: %d, Time: %4.2f sec', i, t));
        htitle = title(height2d, sprintf('Height: %4.2f m, Time: %4.2f sec', 0, t));
        utitle = title(u2d,sprintf('Input control force: %4.2f N', 0));

        % Moving text initialization
        txt =  text(u2d,0,0,sprintf('Joystick Up'));
        txt.FontWeight = 'bold';
        txth = text(height2d,-0.1,0,sprintf('Floor:%d',0));
        txth.FontWeight = 'bold';
    end
    % Control algorithm
    u(i,1) = mass*(gravity + Kp*(des_height-act_height)+Kd*(des_vel-act_vel));
 
    % control thrust limit condition
    control_force(i,1) = min(max(u(i,1),min_thrust),max_thrust); 
    
    %Equation of motion
    a(i,1) = (control_force(i,1) - mass*gravity)/mass;

    % Euler Integration used for easy understanding
    v(i,1) = a(i)*tstep + ini_vel;
    h(i,1) = v(i)*tstep + ini_pos;
    ini_vel = v(i,1);
    ini_pos = h(i,1);
    act_height = h(i,1);
    act_vel = v(i,1);
    t = t+tstep;
    tsave(i,1) = t; 
end
%% ------------------------------ Plotting --------------------------------
for j=1:n_iter
    if rem(n_iter,10) == 0
       % Plot 
       set(tplot,'XData',tsave(j),'YData',h(j));
       set(hplot,'XData',0,'YData',h(j));
       set(uplot,'XData',tsave(j),'YData',control_force(j))
       set(m_plot,'XData',[-0.2 0.2],'YData',[h(j) h(j)]);
       
       % Plot for moving dots
       plot(height2d,0,h(j),'or','MarkerSize', 1)
       plot(u2d,tsave(j),control_force(j),'o','Color',[0.5 0 0.8],'MarkerSize',2)
       plot(tstep2d,tsave(j),h(j),'o','Color',[0.8500 0.3250 0.0980],'MarkerSize',2)
       
       % title 
       set(ttitle, 'String', sprintf(['' ...
           'Iteration: %d, Time: %4.2f sec'], j,tsave(j)))
       set(htitle, 'String', sprintf('Height: %4.2f m, Time: %4.2f sec', h(j), tsave(j)))
       set(utitle, 'String', sprintf('Input control force: %4.2f N', control_force(j)));
       
       % Moving Text
       if control_force(j) >= 1.2*mass*gravity
           txt.String = 'Joystick Up';
       elseif control_force(j) >= 0 && control_force(j)<= 0.1*mass*gravity
           txt.String = 'Joystick Down';
       else
           txt.String = 'Joystick Hold';
       end
       txt.Position=[tsave(j) control_force(j) 0];
       txth.Position = [-0.1 h(j)+0.2 0];
       txth.String = sprintf('Floor: %d',round(h(j)));
       %
       pause(0.01)
       drawnow
       hold all
       if video_on
           writeVideo(video_write, getframe(fig1))
       end       
    end
  
end
if video_on
   close(video_write)
end
% Plot full data
set(tplot,'XData',tsave,'YData',h,'Color',[0.0 0.0 0.0],'MarkerSize', 10);
set(uplot,'XData',tsave,'YData',control_force,'Color',[0 0 0],'MarkerSize', 10);
%% ------------------------------ END -----------------------------------
