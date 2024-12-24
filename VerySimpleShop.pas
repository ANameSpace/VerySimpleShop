program VerySimpleShop;

// Importing the necessary libraries.
uses
  Crt;
 
type 
  Button = (UP, DOWN, LEFT, RIGHT, ESC, ENTER, UNKNOWN);
  ProgramPhase = (WAITING, SHOPPING, PAYING, ENDING, EXITING);
  
  // Product Object.
  TSimpleProduct = class
    private
      fName: string;
      fPrice: integer;
      fCount: integer;
    public
      // TSimpleProduct constructor.
      constructor Create(Name: string; Price: integer);
      begin
        fName := if Name = nil then 'NULL' else Name;
        fPrice := if Price < 1 then 1 else Price;
        fCount := 0;
      end;
      
      // If we want to change fields without methods (just small note).
      property Price: integer read fPrice;
      
      // Methods.
      function ToString: string; override;
      procedure WriteToFile(var chequeFile: TextFile);
      procedure ResetCount;
      function AddCount: Boolean;
      function RemCount: Boolean;
  end;
  
  TTransaction = record
    cardNumber: Integer;
    isSuccess: Boolean;
  end;

const
  TITLE: String = 'VerySimpleShop | ';
  INPUT_CHAR: Char = '_';
  HIDDEN_INPUT_CHAR: Char = '*';
  OFFSET: Integer = 7;
  CURSOR_CHAR: Char = '>';
  
var
  currentPhase: ProgramPhase;
  products: array of TSimpleProduct;
  productsCount: Integer; 
  currentPosition: integer := 0;
  totalPrice: integer := 0;

// A method for displaying product information in console.
function TSimpleProduct.ToString: string;
begin
  Result := (if fCount > 0 then '[x]' else '[ ]') + ($' "{fName}" - {fPrice}$ x {fCount} pcs. = {fPrice * fCount}$') + StringOfChar(' ', 10);
end;

// Write product to cheque.txt.
procedure TSimpleProduct.WriteToFile(var chequeFile: TextFile);
begin
  if fCount > 0 then
  begin
    WriteLn(chequeFile, $' "{fName}" - {fPrice}$ x {fCount} pcs. = {fPrice * fCount}$');
  end;
end;

// Reset the amount of product.
procedure TSimpleProduct.ResetCount();
begin
  fCount := 0;
end;

// Increase the amount of product.
function TSimpleProduct.AddCount(): Boolean;
begin
  Result := false;
  if fCount < 16 then
  begin
    fCount := fCount + 1;
    Result := true;
  end;
end;

// Reduce the amount of product.
function TSimpleProduct.RemCount(): Boolean;
begin
  Result := false;
  if fCount > 0 then
  begin
    fCount := fCount - 1;
    Result := true;
  end;
end;


//
// UTILS
//

// Get pressed button
function ReadInput(): Button;
var
  ch: Char;
begin
  ch := ReadKey();
  case ch of
    #0 : begin
      ch := ReadKey();
      case ch of
        #37 : Result := Button.LEFT;
        #38 : Result := Button.UP;
        #39 : Result := Button.RIGHT;
        #40 : Result := Button.DOWN;
      end;
    end;
    #13 : Result := Button.ENTER;
    #27 : Result := Button.ESC;
    else Result := Button.UNKNOWN;
  end;
end;

// Add char to input and print it.
procedure AddToInput(inputChar:Char; var currentInput:String; var currentLength:Integer; hideInput:Boolean);
begin
  Write(if hideInput then HIDDEN_INPUT_CHAR else inputChar);
  currentLength := currentLength + 1;
  currentInput := currentInput + inputChar;
end;

// Get input integer.
function ReadIntInput(inputLength:Integer; inputX:Integer; inputY:Integer; hideInput:Boolean): Integer;
var
  ch: Char;
  currentLength: Integer := 0;
  currentInput: String := '';
begin
  Crt.GotoXY(inputX, inputY);
  Write(StringOfChar(INPUT_CHAR, inputLength));
  Crt.GotoXY(inputX, inputY);
  
  while currentLength <> inputLength do
  begin
    ch := ReadKey();
    case ch of
      #48 : AddToInput('0', currentInput, currentLength, hideInput);
      #49 : AddToInput('1', currentInput, currentLength, hideInput);
      #50 : AddToInput('2', currentInput, currentLength, hideInput);
      #51 : AddToInput('3', currentInput, currentLength, hideInput);
      #52 : AddToInput('4', currentInput, currentLength, hideInput);
      #53 : AddToInput('5', currentInput, currentLength, hideInput);
      #54 : AddToInput('6', currentInput, currentLength, hideInput);
      #55 : AddToInput('7', currentInput, currentLength, hideInput);
      #56 : AddToInput('8', currentInput, currentLength, hideInput);
      #57 : AddToInput('9', currentInput, currentLength, hideInput);
      #8 : begin
        if currentLength > 0 then
        begin
          currentInput := Copy(currentInput, 1, currentLength - 1);
          
          inputX := Crt.WhereX() - 1;
          Crt.GotoXY(inputX, inputY);
          Write(INPUT_CHAR);
          
          Crt.GotoXY(inputX, inputY);
          currentLength -= 1;
        end;
      end;
    end;
  end;
  
  try
    Result := StrToInt(currentInput);
  except
    // Just in case.
    Result := 0;
  end;
end;

// Clear the selection of products.
procedure ResetProductsCount();
begin
  currentPosition := 0;
  totalPrice := 0;
  for i:Integer := 0 to High(products) do
  begin
    Products[i].ResetCount();
  end;
end;

// Create cheque.txt.
procedure CreateCheque(transaction: TTransaction);
var
  chequeFile: TextFile;
begin
  AssignFile(chequeFile, 'cheque.txt');
  Rewrite(chequeFile);
  
  WriteLn(chequeFile, '----------------------------------------');
  WriteLn(chequeFile, ' VerySimpleShop');
  WriteLn(chequeFile, '');
  WriteLn(chequeFile, 'Date and time: ');
  WriteLn(chequeFile, DateTime.Now.ToString('yyyy-MM-dd HH:mm:ss'));
  WriteLn(chequeFile, '');
  WriteLn(chequeFile, 'Items:');
  for i:Integer := 0 to productsCount do
  begin
    Products[i].WriteToFile(chequeFile);
  end;
  WriteLn(chequeFile, '');
  WriteLn(chequeFile, 'Total: ' + totalPrice.ToString() + '$');
  WriteLn(chequeFile, '----------------------------------------');
  
  CloseFile(chequeFile);
end;


//
// SCREENS
//

// Show welcome screen.
procedure WelcomeScreen;
begin
  Crt.ClrScr(); // Clear Screen.
  currentPhase := ProgramPhase.WAITING;
  Crt.SetWindowTitle(TITLE + 'Welcome');
  
  Crt.TextColor(Crt.Yellow);  // Set terminal text color.
  WriteLn(' __   __            ___ _            _     ___ _             ');
  WriteLn(' \ \ / /__ _ _ _  _/ __(_)_ __  _ __| |___/ __| |_  ___ _ __ ');
  WriteLn('  \ V / -_) ''_| || \__ \ | ''  \| ''_ \ / -_)__ \ '' \/ _ \ ''_ \');
  WriteLn('   \_/\___|_|  \_, |___/_|_|_|_| .__/_\___|___/_||_\___/ .__/');
  WriteLn('               |__/            |_|                     |_|   ');
  Crt.TextColor(Crt.White);
  WriteLn();
  WriteLn('           We are glad to welcome you to our store!');
  WriteLn();
  Crt.TextColor(Crt.LightGray);
  WriteLn(' This is a small educational project distributed under MIT License.');
  WriteLn('       You can find the source code and more information');
  WriteLn(' on GitHub repository: https://github.com/ANameSpace/VerySimpleShop');
  WriteLn();
  Crt.TextColor(Crt.White);
  WriteLn('Press any key to start or ESC to quit.');
  
  if ReadInput() = Button.ESC then
  begin
    Crt.ClrScr();
    currentPhase := ProgramPhase.EXITING;
    Halt(0); // Program termination with code 0.
  end;
end;

// Show error screen.
procedure ErrorScreen(description: String);
var
  btn: Button;
begin
  Crt.ClrScr();
  currentPhase := ProgramPhase.EXITING;
  Crt.SetWindowTitle(TITLE + 'Error');
  
  Crt.TextColor(Crt.LightRed);
  WriteLn('  ___ ___ ___  ___  ___ _ ');
  WriteLn(' | __| _ \ _ \/ _ \| _ \ |');
  WriteLn(' | _||   /   / (_) |   /_|');
  WriteLn(' |___|_|_\_|_\\___/|_|_(_)');
  WriteLn('                          ');
  Crt.TextColor(Crt.LightGray);
  WriteLn('A critical error occurred while the program was running.');
  Write('Info: ');
  Crt.TextColor(Crt.White);
  WriteLn(description);
  WriteLn();
  WriteLn('Press ESC to quit.');
  
  repeat
    btn :=  ReadInput();
  until btn = Button.ESC;
  Crt.ClrScr();
  Halt(0);
end;

// Shop screen move cursor.
procedure ShopScreenMoveCursor(cursorMove: Integer);
begin
  if currentPhase <> ProgramPhase.SHOPPING then // <> <---> !=
  begin
    raise new System.ArgumentException('The operation cannot be performed in the current phase of the program.');
  end;
  
  // Clear.
  Crt.GotoXY(1, OFFSET + currentPosition);
  Write(' ');
  currentPosition += cursorMove;
  // Print.     
  Crt.GotoXY(1, OFFSET + currentPosition);
  Crt.TextColor(Crt.Yellow);
  Write(CURSOR_CHAR);
  Crt.TextColor(Crt.White);
end;

// Shop screen update product info.
procedure ShopScreenUpdateProduct();
begin
  if currentPhase <> ProgramPhase.SHOPPING then
  begin
    raise new System.ArgumentException('The operation cannot be performed in the current phase of the program.');
  end;
  
  Crt.GotoXY(2, OFFSET + currentPosition);
  Write(products[currentPosition]);
  
  Crt.GotoXY(1, OFFSET + productsCount + 2);
  Crt.ClearLine();
  Write('Total: ', totalPrice, '$');
end;

// Show shop screen.
procedure ShopScreen();
var
  btn: Button;
begin
  Crt.ClrScr();
  currentPhase := ProgramPhase.SHOPPING;
  Crt.SetWindowTitle(TITLE + 'Shop');
  
  Crt.TextColor(Crt.Yellow);
  WriteLn('SELECT THE PRODUCT:');
  WriteLn();
  Crt.TextColor(Crt.LightGray);
  WriteLn('| UP/DOWN - Move the cursor.');
  WriteLn('| LEFT/RIGHT - Change the number of items in the shopping cart.');
  WriteLn('| ENTER - Proceed to payment or exit.');
  WriteLn();
  Crt.TextColor(Crt.White);
  
  for i:Integer := 0 to productsCount do
  begin
    Write(' '); // Place for the cursor.
    WriteLn(Products[i]);
  end;
  
  ShopScreenMoveCursor(0);
  ShopScreenUpdateProduct();
  
  // Main loop.
  repeat
    btn :=  ReadInput();
    case btn of
    Button.UP : begin
      if currentPosition <> 0 then
      begin
        ShopScreenMoveCursor(-1);
      end;
    end;
    Button.DOWN : begin
      if currentPosition <> productsCount then
      begin
        ShopScreenMoveCursor(1);
      end;
    end;
    Button.LEFT : begin
      var product: TSimpleProduct := products[currentPosition];
      if product.RemCount() then
      begin
        totalPrice -= product.Price;
        ShopScreenUpdateProduct();
      end;
    end;
    Button.RIGHT : begin
      var product: TSimpleProduct := products[currentPosition];
      if product.AddCount() then
      begin
        totalPrice += product.Price;
        ShopScreenUpdateProduct();
      end;
    end;
    Button.ESC : begin
      ResetProductsCount();
      exit;
    end;
  end;
  until btn = Button.ENTER;
  
  if totalPrice > 0 then
  begin
    currentPhase := ProgramPhase.PAYING;
  end;
end;

// Show pay screen and get result.
function PayScreen(): TTransaction;
var
  cardNumber: Integer;
  cardCVV: Integer;
begin
  Crt.ClrScr();
  Crt.SetWindowTitle(TITLE + 'Pay');
  
  Crt.TextColor(Crt.Yellow);
  WriteLn('ENTER YOUR CARD DETAILS:');
  Crt.TextColor(Crt.LightGray);
  WriteLn('(You can enter any card number value. CVV - 123)');
  WriteLn();
  Crt.TextColor(Crt.White);
  WriteLn('____________________________________');
  WriteLn('|  Card number:                    |');
  WriteLn('|                                  |');
  WriteLn('|                                  |');
  WriteLn('|                             CVV: |');
  WriteLn('|                                  |');
  WriteLn('|                                  |');
  WriteLn('|__________________________________|');
  
  Crt.TextColor(Crt.Yellow);
  cardNumber := ReadIntInput(16, 4, 6, false);
  cardCVV := ReadIntInput(3, 31, 9, true);
  Crt.TextColor(Crt.White);

  var transaction: TTransaction := new TTransaction();
  transaction.cardNumber := cardNumber;
  transaction.isSuccess := (cardCVV = 123);
  Result := transaction;
end;

// Show end screen.
procedure EndScreen(transaction: TTransaction);
begin
  Crt.ClrScr();
  currentPhase := ProgramPhase.ENDING;
  Crt.SetWindowTitle(TITLE + 'Goodbye');
  
  Crt.TextColor(Crt.Yellow);
  WriteLn('   ___              _ _             _ ');
  WriteLn('  / __|___  ___  __| | |__ _  _ ___| |');
  WriteLn(' | (_ / _ \/ _ \/ _` | ''_ \ || / -_)_|');
  WriteLn('  \___\___/\___/\__,_|_.__/\_, \___(_)');
  WriteLn('                           |__/       ');
  Crt.TextColor(Crt.White);
  WriteLn();
  if transaction.isSuccess then
  begin
    WriteLn('     Thank you for your purchase!');
    WriteLn(' Your receipt is in the file cheque.txt.');
    CreateCheque(transaction);
  end
  else
  begin
    WriteLn('There are not enough money on the card!');
    WriteLn('You were unable to make the purchase.');
  end;
  Crt.TextColor(Crt.LightGray);
  
  ResetProductsCount();
  
  for i: Integer := 5 downto 1 do
  begin
    Crt.GotoXY(1, 10);
    WriteLn('Transitioning to the main screen in ', i, ' seconds...');
    Crt.Delay(1000);
  end;
  Crt.TextColor(Crt.White);
  
  // Reading all buttons pressed during this time (Without this, the program will immediately transition to the shop screen).
  while Crt.KeyPressed() do
  begin
    Crt.ReadKey();
  end;
end;


//
// Main block of the program.
//
begin 
  SetLength(products, 5);
  Products[0] := TSimpleProduct.Create('Phone 15 Pro', 500);
  Products[1] := TSimpleProduct.Create('Phone 15', 450);
  Products[2] := TSimpleProduct.Create('Phone 14 Pro', 300);
  Products[3] := TSimpleProduct.Create('Phone 14', 250);
  Products[4] := TSimpleProduct.Create('Phone 1 Pro', 9999);
  productsCount := High(products); 

  Crt.HideCursor();
  
  // Main loop.
  while currentPhase <> ProgramPhase.EXITING do
  begin
    WelcomeScreen();
    ShopScreen();
    if currentPhase = ProgramPhase.PAYING then
    begin
      EndScreen(PayScreen());
    end;
  end;
end.