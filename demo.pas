uses ABCObjects, GraphABC, Timers, System.Media, BCWalls; 
var
  paused, spawningEnabled: boolean;
  moveSpeed, resX, resY, lm, lt, ti, tx, ty, ttyp: integer;
  ci, cx, cy, ctyp, entlimit, bonuslimit, bonusamount: integer;
  spawnPoints: array [,] of integer := new integer[1, 3];
  f{, cfg}: text;
  tGame, spawner: Timer;
  HealthStatus: array of RectangleABC := new RectangleABC[2];
  lvls: array of string := new string[2];
  statusBar: RectangleABC;
  //Static obj------------------------------------------------------------------

var
  map: array of static := new static[1];

  //Player----------------------------------------------------------------------

type
  shell = class(PictureABC)
  
  private 
    dir, dmg, own, bulletSpeed: shortint;
    c: integer;
    t: timer;
    f1, f2: soundplayer;
    
    procedure Shot();
    
    constructor create(x, y, direction, damage, owner, speed: integer);
    begin
    
      Create(x + 1, y + 1, 'masleenaY.png');
      lockGraphics();
      case direction of
        1:
          begin
            changePicture('masleenaX.png');
            flipHorizontal;
          end;
        2: flipVertical;
        3: changePicture('masleenaX.png');
      end;
      (dir, dmg, own) := (direction, damage, owner);
      t := new timer(14, shot);
      t.start;
      ToBack;
      bulletSpeed := speed;
      f1 := new System.Media.SoundPlayer('7.wav');
      f2 := new System.Media.SoundPlayer('hit3.wav');
      unlockGraphics();
    end;
    
    procedure dest();
    begin
      t.stop;
      Destroy;
      Finalize;
    end;
  end;

type
  tank = class
  private 
    name: string;
    texture: PictureABC;
    isSpawned, AI, u, d, l, r, bfly: boolean;
    direction, lives, hp, lastX, lastY, defaultHP, bulletSpeed: integer;
    xdmg: real;
    tx, ty: string;
    tMove, tRand: Timer;
    
    ucode, dcode, lcode, rcode, shcode: integer;
    upKey, downKey, leftKey, rightKey, fire: boolean;
  
  public 
    constructor(n: string; spawnX, spawnY, lives, hp: integer; enableAI: boolean);
    begin
      name := n;
      case enableAI of
        false:
          begin
            tx := 'yellow_x.png';
            ty := 'yellow_y.png';
          end;
        true:
          begin
            tx := 'yellow_xe.png';
            ty := 'yellow_ye.png';
          end;
      end;
      (lastX, lastY) := (spawnX, spawnY);
      texture := new PictureABC(spawnX, spawnY, ty);
      AI := enableAI;
      direction := 0;
      bfly := false;
      texture.ToBack;
      isSpawned := true;
      xdmg := 1;
      self.lives := lives;
      self.hp := hp;
      defaultHP := hp;
      fire := true;
      bulletSpeed := 10;
      sleep(10);
    end;
    
    destructor destroy();
    begin
      {if (tMove <> nil) and (tRand <> nil) then begin}
      tMove.stop;
      tRand.stop;
      tMove := nil;
      tRand := nil;
      //end;
      texture.ScaleX := 0;
      texture.ScaleY := 0;
      texture.Destroy;
      finalize;
      isSpawned := false;
      sleep(10);
    end;
    
    procedure hit(dmg: integer);
    begin
      hp -= dmg;
      var ff := new System.Media.SoundPlayer('hit1.wav');
      ff.Play;
      if hp <= 0 then begin
        lives -= 1;
        if lives >= 1 then begin
          isSpawned := false;
          texture.Visible := false;
          var f := new System.Media.SoundPlayer('0.wav');
          f.Play;
          sleep(1000);
          texture.MoveTo(lastX, lastY);
          hp := defaultHP;
          isSpawned := true;
          texture.Visible := true;
        end
        else 
          destroy;
      end;
    end;
    
    procedure shoot(dmg, own: integer);
    begin
      shell.Create(texture.Center.X - 3, texture.Center.Y - 3, direction, dmg, own, bulletSpeed);
      sleep(10);
      bfly := true;
    end;
  end;

procedure move(subj: tank; u, d, l, r: boolean);
begin
  if subj.isSpawned then begin
    var x, y: integer;
    //check for nearby obstacles--------------------------------------------------
    for var i := 0 to map.Length - 1 do 
    begin
      
      if (map[i].t = 1) or (map[i].t = 0) or (map[i].t = 3) then begin
        if ((subj.texture.Bounds.Right) in Range(map[i].texture.Bounds.Left + moveSpeed, map[i].texture.Bounds.Right - moveSpeed)) and (subj.texture.Position.Y in Range(map[i].texture.Bounds.Top + 2 * moveSpeed - subj.texture.Height, map[i].texture.Bounds.Bottom - moveSpeed)) then subj.r := true;
        if ((subj.texture.Bounds.Right - moveSpeed - subj.texture.Width) in Range(map[i].texture.Bounds.Left + moveSpeed, map[i].texture.Bounds.Right - moveSpeed)) and (subj.texture.Position.Y in Range(map[i].texture.Bounds.Top + moveSpeed - subj.texture.Height + moveSpeed, map[i].texture.Bounds.Bottom - moveSpeed)) then subj.l := true;
        if (subj.texture.Bounds.Top - moveSpeed in Range(map[i].texture.Bounds.Top + moveSpeed, map[i].texture.Bounds.Bottom - moveSpeed)) and (subj.texture.Position.X in Range(map[i].texture.Bounds.Left + 2 * moveSpeed - subj.texture.Width, map[i].texture.Bounds.Right - moveSpeed)) then subj.u := true;
        if (subj.texture.Bounds.Top + subj.texture.Bounds.Height in Range(map[i].texture.Bounds.Top + moveSpeed, map[i].texture.Bounds.Bottom - moveSpeed)) and (subj.texture.Position.X in Range(map[i].texture.Bounds.Left + moveSpeed - subj.texture.Width + moveSpeed, map[i].texture.Bounds.Right - moveSpeed)) then subj.d := true;
      end;
      
      if l and subj.l then
        if (subj.texture.Position.Y - map[i].texture.Position.Y in range(24, 31)) then begin
          subj.texture.MoveOn(0, movespeed);
          break;
        end else
        if (subj.texture.Position.Y - map[i].texture.Position.Y in range(-31, -24)) then begin
          subj.texture.MoveOn(0, -movespeed);
          break;
        end;
      
      if r and subj.r then
        if (subj.texture.Position.Y - map[i].texture.Position.Y in range(24, 31)) then begin
          subj.texture.MoveOn(0, movespeed);
          break;
        end else
        if (subj.texture.Position.Y - map[i].texture.Position.Y in range(-31, -24)) then begin
          subj.texture.MoveOn(0, -movespeed);
          break;
        end;
      
      if d and subj.d then
        if (subj.texture.Position.X - map[i].texture.Position.X in range(24, 31)) then begin
          subj.texture.MoveOn(movespeed, 0);
          break;
        end else
        if (subj.texture.Position.X - map[i].texture.Position.X in range(-31, -24)) then begin
          subj.texture.MoveOn(-movespeed, 0);
          break;
        end;
      
      if u and subj.u then
        if (subj.texture.Position.X - map[i].texture.Position.X in range(24, 31)) then begin
          subj.texture.MoveOn(movespeed, 0);
          break;
        end else
        if (subj.texture.Position.X - map[i].texture.Position.X in range(-31, -24)) then begin
          subj.texture.MoveOn(-movespeed, 0);
          break;
        end;
      
    end;
    if subj.texture.Left = 0 then subj.l := true else 
    if subj.texture.Position.X + subj.texture.Width = resX + 2 then subj.r := true;
    if subj.texture.Top = 0 then subj.u := true else 
    if subj.texture.Position.Y + subj.texture.Height = resY + 2 then subj.d := true;
    //end of check----------------------------------------------------------------
    if u or d then begin
      if u then begin
        if not subj.u then y -= moveSpeed;
        if (subj.direction = 1) or (subj.direction = 3) then subj.texture.ChangePicture(subj.ty);
        if subj.direction <> 0 then begin
          subj.texture.ScaleY := 1;
          subj.direction := 0;
        end;
      end;
      if d then begin
        if not subj.d then y += moveSpeed;
        if (subj.direction = 1) or (subj.direction = 3) then subj.texture.ChangePicture(subj.ty);
        if subj.direction <> 2 then begin
          subj.texture.ScaleY := -1;
          subj.direction := 2;
        end;
      end;
    end else begin
      if l then begin
        if not subj.l then x -= moveSpeed;
        if (subj.direction = 0) or (subj.direction = 2) then subj.texture.ChangePicture(subj.tx);
        if subj.direction <> 3 then begin
          subj.texture.ScaleX := 1;
          subj.direction := 3;
        end;
      end;
      if r then begin
        if not subj.r then x += moveSpeed;
        if (subj.direction = 0) or (subj.direction = 2) then subj.texture.ChangePicture(subj.tx);
        if subj.direction <> 1 then begin
          subj.texture.ScaleX := -1;
          subj.direction := 1;
        end;
      end;
    end;
    subj.texture.MoveOn(x, y);
    subj.l := false;
    subj.d := false;
    subj.u := false;
    subj.r := false;
  end;
end;

//the actual classes-------------------------------------------------------

type
  player = class(tank)
  public 
    procedure mv();
    begin
      move(self, upKey, downKey, leftKey, rightKey);
    end;
  end;

var
  players: array of player := new player[1];

type
  enemy = class(tank)
  private 
    t, r: integer;
  public 
    procedure mv();
    begin
      lockGraphics();
      case t of
        0: move(self, false, false, false, true);
        1: move(self, false, false, true, false);
        2: move(self, true, false, false, false);
        3: move(self, false, true, false, false);
      end;
      unlockGraphics();
      r := Random(0, 128);
      if r = 42 then shoot(random(10, 40), 1);
    end;
    
    procedure calculateRandom();
    begin
      t := Random(0, 3);
    end;
    
    constructor create(n: string; sX, sY, diff: integer; eAI: boolean);
    begin
      create(n, sX, sY, 1, 100, eAI);
      tRand := new Timer(500, calculateRandom);
      tMove := new Timer(12, mv);
      tRand.Start;
      tMove.Start;
      texture.ToBack();
      sleep(100);
    end;
  
  end;

var
  ent: array of enemy := new enemy[0];//----------------------------------------

type
  bonus = class(PictureABC)
  private 
    typ, l, lifeTime: smallint;
    texture: string;
    isPickable: boolean;
    t: Timer;
    
    procedure blink();
    begin
      if isPickable then
        for var i := 0 to players.Length - 1 do
          if players[i].texture.PtInside(center.X, center.Y) then case typ of
              1:
                begin
                  if (players[i].xdmg <= 15) then players[i].xdmg := 1.25 * players[i].xdmg;
                  players[i].hp += 50;
                  players[i].bulletSpeed := Round(players[i].bulletSpeed * 1.25);
                  HealthStatus[i].Text := (players[i].hp.ToString + ' HP || ' + players[i].lives.ToString + ' lives');
                  scaleX := 0;
                  scaleY := 0;
                  Destroy;
                  bonusAmount -=1;
                end;
              2:
                begin
                  players[i].hp += 100;
                  HealthStatus[i].Text := (players[i].hp.ToString + ' HP || ' + players[i].lives.ToString + ' lives');
                  scaleX := 0;
                  scaleY := 0;
                  Destroy;
                  bonusAmount -=1;
                end;
              3:
                begin
                  for var k := 0 to ent.Length - 1 do 
                  begin
                    ent[k].tMove.Stop;
                    ent[k].tRand.Stop;
                  end;
                  scaleX := 0;
                  scaleY := 0;
                  Destroy;
                  bonusAmount -=1;
                end;
            end;
      inc(l);
      if l >= lifetime then begin
        Destroy;
        bonusAmount -=1;
        isPickable := false;
        t.Stop;
      end;
    end;
    
    constructor create();
    begin
      create((Random(0, resX) div 32) * 32, (Random(0, resY) div 32) * 32, 'brick.png');
      t := new Timer(1000, blink);
      lifeTime := 13;
      l := 0;
      isPickable := true;
      typ := random(1, 3);
      case typ of
        1: changePicture('star.png');
        2: changePicture('helmet.png');
        3: changePicture('za_warudo.png');
      end;
      t := new Timer(1000, blink);
      t.Start;
    end;
  end;

procedure shell.Shot();
{$omp parallel for}
begin
  if not paused then begin
  inc(c);
    case dir of
      0: MoveOn(0, -bulletSpeed);
      1: MoveOn(bulletSpeed, 0);
      2: MoveOn(0, bulletSpeed);
      3: MoveOn(-bulletSpeed, 0);
    end;
    if c mod 3 = 2 then begin
    for var i := 0 to map.Length - 1 do
    begin
      if (map[i].dest <> 2) then if map[i].texture.PtInside(Center.X, Center.Y) then begin
          if (map[i].dest = 1) then begin
            f1.Play;
            map[i].destroy;
          end else begin
            f2.Play;
          end;
          dest;
        end;
    end;
    end;
    case dir of
      0: if position.Y < 0 then dest;
      1: if position.X > resX then dest;
      2: if position.Y > resY then dest;
      3: if position.X < 0 then dest;
    end;
  if c mod 3 = 0 then case own of
    0:
      begin
        for var i := 0 to ent.Length - 1 do
          if ent[i].texture.PtInside(center.X, center.Y) then begin
            ent[i].hit(dmg);
            if ent[i].lives <= 0 then begin
              swap(ent[i], ent[ent.GetLength(0) - 1]);
              ent[ent.GetLength(0) - 1] := nil;
              setLength(ent, ent.GetLength(0) - 1);
            end;
            dest;
          end;
      end;
    1:
      begin
        for var i := 0 to players.Length - 1 do
          if players[i].texture.PtInside(center.X, center.Y) then begin
            dest;
            players[i].hit(dmg);
            HealthStatus[i].Text := (players[i].hp.ToString + ' HP || ' + players[i].lives.ToString + ' lives');
          end;
      end;
  end;
  end;
end;

// end of classes---------------------------------------------------------------

procedure spawnEnemy();
var
  rnum, rtyp: integer;
begin
  if (ent.Length < entlimit) then begin
    setLength(ent, ent.GetLength(0) + 1);
    while rtyp <> 1 do 
    begin
      rnum := random(0, spawnPoints.GetLength(0) - 1);
      rtyp := spawnPoints[rnum, 2];
    end;
    ent[ent.GetLength(0) - 1] := new enemy('null', spawnPoints[rnum, 0], spawnPoints[rnum, 1], 0, true);
    if paused then begin
      ent[ent.GetLength(0) - 1].tMove.stop;
      ent[ent.GetLength(0) - 1].tRand.stop;
    end;
  end;
end;

var
  pI: array of RectangleABC := new RectangleABC[4];

procedure openPause();
begin
  case paused of
    true:
      begin
        for var i := 0 to ent.Length - 1 do 
          if ent[i].isSpawned then
          begin
            ent[i].tMove.start;
            ent[i].tRand.start;
          end;
        if spawningEnabled then spawner.Start;
        pI[0].Destroy;
        pI[1].Destroy;
        pI[2].Destroy;
        pI[3].Destroy;
        paused := false;
      end;
    false:
      begin
        for var i := 0 to ent.Length - 1 do 
        begin
          ent[i].tMove.stop;
          ent[i].tRand.stop;
        end;
        pI[0] := new RectangleABC(resX div 2 - 125, resY div 2 + 35, 250, 30, clDarkGray);
        pI[0].Text := 'Quit';
        pI[1] := new RectangleABC(resX div 2 - 125, resY div 2 - 70, 250, 30, clDarkGray);
        pI[1].Text := 'Countinue';
        pI[2] := new RectangleABC(resX div 2 - 125, resY div 2 - 35, 250, 30, clDarkGray);
        pI[2].Text := 'Add an enemy';
        pI[3] := new RectangleABC(resX div 2 - 125, resY div 2, 250, 30, clDarkGray);
        case spawner.Enabled of
          true: pI[3].Text := 'Autospawning || ON';
          false: pI[3].Text := 'Autospawning || OFF';
        end;
        paused := true;
        for var i := 0 to players.Length - 1 do 
        begin
          players[i].upKey := false;
          players[i].downKey := false;
          players[i].leftKey := false;
          players[i].rightKey := false;
        end;
        spawner.Stop;
      end;
  end;
end;

procedure mDown(x, y, mb: integer);
begin
  if paused and (mb = 1) then begin
    if pI[0].PtInside(x, y) then begin
      println('Goodbye!');
      sleep(1000);
      window.Close;
    end;
    if pI[1].PtInside(x, y) then openPause;
    if pI[2].PtInside(x, y) then
      if (ent.GetLength(0) + 1 <= entlimit) then begin
      spawnEnemy;
      sleep(300);
      end;
    if pI[3].PtInside(x, y) then case spawningEnabled of
        true:
          begin
            spawner.Stop;
            spawningEnabled := false;
            pI[3].Text := 'Autospawning || OFF';
          end;
        false:
          begin
            spawner.Start;
            spawningEnabled := true;
            pI[3].Text := 'Autospawning || ON';
          end;
      end;
  end;
end;

procedure keyDown(Key: integer);
begin
  if not paused then for var i := 0 to players.Length - 1 do 
    begin
      if key = players[i].rcode then players[i].rightKey := true;
      if key = players[i].dcode then players[i].downKey := true;
      if key = players[i].lcode then players[i].leftKey := true;
      if key = players[i].ucode then players[i].upKey := true;
      if key = players[i].shcode then
      begin
        if players[i].fire then begin
          LockGraphics();
          players[i].shoot(Random(75, 125), 0);
          UnlockGraphics();
          players[i].fire := false;
        end;
      end;
    end;
  if key = VK_Escape then openPause;
  if (key = VK_J) and (bonusAmount <= bonuslimit) then begin
  bonus.Create;
  bonusAmount += 1;
  end;
end;

procedure keyUp(Key: integer);
begin
  for var i := 0 to players.Length - 1 do 
  begin
    if key = players[i].rcode then players[i].rightKey := false;
    if key = players[i].dcode then players[i].downKey := false;
    if key = players[i].lcode then players[i].leftKey := false;
    if key = players[i].ucode then players[i].upKey := false;
    if key = players[i].shcode then players[i].fire := true;
  end;
end;

//Процесс игры------------------------------------------------------------------

procedure gameRun();
begin
  for var i := 0 to players.Length - 1 do
    if players[i].upKey or players[i].downKey or players[i].leftKey or players[i].rightKey then begin
      LockGraphics();
      players[i].mv();
      UnlockGraphics();
    end;
end;

var
  menuButtons: array of RectangleABC := new RectangleABC[4];
  bckground: PictureABC;

type
  game = class
    
    procedure stop();
    begin
      for var i := 0 to players.Length - 1 do players[i].destroy;
      for var i := 0 to ent.Length - 1 do ent[i].destroy;
      tGame.stop;
      for var i := 0 to map.Length - 1 do map[i].destroy;
      map := nil;
      HealthStatus[0].Destroy;
      HealthStatus[1].Destroy;
      statusBar.Destroy;
      spawner.stop;
    end;
    
    procedure startGame(lvl: integer; twoplayers: boolean);
    
    //Methods in menu---------------------------------------------------------------
    
    procedure closeMenu();
    begin
      for var i := 0 to menuButtons.Length - 1 do menuButtons[i].Destroy;
      onMouseDown := nil;
      onMouseMove := nil;
    end;
    
    procedure onmdown_menu(x, y, mb: integer);
    begin
      if mb = 1 then begin
        if menuButtons[0].PtInside(x, y) then begin
          closeMenu();
          startGame(0, false);
          var s := new soundplayer('buttonClickRelease.wav');
          s.Play;
          bckground.Destroy;
          bckground := nil;
        end;
        if menuButtons[1].PtInside(x, y) then begin
          var s := new soundplayer('buttonClickRelease.wav');
          s.Play;
          closeMenu();
          startGame(0, true);
          bckground.Destroy;
          bckground := nil;
        end;
        if menuButtons[2].PtInside(x, y) then begin
          var s := new soundplayer('buttonClickRelease.wav');
          s.Play;
        end;
        if menuButtons[3].PtInside(x, y) then
        window.Close;
      end;
    end;
    
    procedure onmmove_menu(x, y, mb: integer);
    begin
      for var i := 0 to menuButtons.Length - 1 do 
        if menuButtons[i].PtInside(x, y) then begin
          if menuButtons[i].BorderColor = clDarkGreen then begin
            var s := new System.Media.SoundPlayer('buttonrollover.wav');
            s.Play;
          end;
          menuButtons[i].BorderColor := clBlack;
        end else menuButtons[i].BorderColor := clDarkGray;
    end;
    
    procedure openMenu();
    begin
      bckground := new PictureABC(0, 0, 'alphalogo.png');
      menuButtons[0] := new RectangleABC(5, resY - 145, 250, 30, clBlack);
      menuButtons[1] := new RectangleABC(5, resY - 110, 250, 30, clBlack);
      menuButtons[2] := new RectangleABC(5, resY - 75, 250, 30, clBlack);
      menuButtons[3] := new RectangleABC(5, resY - 40, 250, 30, clBlack);
      menuButtons[0].Text := 'One player';
      menuButtons[1].Text := 'Two players';
      menuButtons[2].Text := 'Options';
      menuButtons[3].Text := 'Quit';
      for var i := 0 to menuButtons.Length - 1 do 
      begin
        menuButtons[i].FontColor := clGhostWhite;
        menuButtons[i].BorderColor := clDarkGray;
      end;
      onMouseDown := onmdown_menu;
      onMouseMove := onmmove_menu;
    end;
  
  end;

//End of methods----------------------------------------------------------------

procedure game.startGame(lvl: integer; twoplayers: boolean);
begin
  moveSpeed := 1;
  statusBar := new RectangleABC(resX, 0, 100, resY, clDarkGray);
  statusBar.BorderColor := clDarkGray;
  ci := 1;
  ti := 1;
  
  begin
    Reset(f, 'sv1.txt');
    read(f, lm);
    setlength(map, lm);
    while not f.SeekEoln do 
    begin
      read(f, cx, cy, ctyp);
      map[ci - 1] := new static(cx, cy, ctyp);
      ci += 1;
    end;
    read(f, lt);
    setlength(spawnPoints, lt, 3);
    while not f.SeekEoln do
    begin
      read(f, tx, ty, ttyp);
      spawnPoints[ti - 1, 0] := tx;
      spawnPoints[ti - 1, 1] := ty;
      spawnPoints[ti - 1, 2] := ttyp;
      ti += 1;
    end;
    close(f);
  end;
  
  HealthStatus[0] := new RectangleABC(resX, resY - 100, 100, 20, clDarkGray);
  HealthStatus[1] := new RectangleABC(resX, resY - 75, 100, 20, clDarkGray);
  
  if twoplayers then setLength(players, 2);
  entlimit := 3;
  bonuslimit := 5;
  players[0] := new player('sus', 0, 32, 3, 100, false);
  if players.Length = 2 then begin
  players[1] := new player('sas', 32, 0, 3, 100, false);
  HealthStatus[1].Text := (players[1].hp.ToString + ' HP || ' + players[1].lives.ToString + ' lives');
  end;
  
  HealthStatus[0].Text := (players[0].hp.ToString + ' HP || ' + players[0].lives.ToString + ' lives');
  HealthStatus[0].BorderColor := clDarkGray;
  HealthStatus[1].BorderColor := clDarkGray;
  //Keycodes--------------------------------------------------------------------
  players[0].ucode := VK_Up;
  players[0].dcode := VK_Down;
  players[0].lcode := VK_Left;
  players[0].rcode := VK_Right;
  players[0].shcode := VK_M;
  
  if players.Length = 2 then begin
    players[1].ucode := VK_W;
    players[1].dcode := VK_S;
    players[1].lcode := VK_A;
    players[1].rcode := VK_D;
    players[1].shcode := VK_Q;
  end;
  //End of keycodes-------------------------------------------------------------
  
  tGame := new Timer(10, gameRun);
  tGame.Start;
  
  spawner := new Timer(5000, spawnEnemy);
  spawningEnabled := false;
  
  paused := false;
  
  OnKeyDown := KeyDown;
  OnKeyUp := KeyUp;
  OnMouseDown := mDown;
end;

var
  g := new game;

begin
  (resX, resY) := (640, 480);
  Window.SetSize(resX + 100, resY);
  Window.IsFixedSize := true;
  Window.Caption := '.pas';
  Window.Clear(clBlack);
  sleep(500);
  g.openMenu;
end.
