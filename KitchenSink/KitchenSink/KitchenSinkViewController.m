//
//  KitchenSinkViewController.m
//  KitchenSink
//
//  Created by David Muñoz Fernández on 10/05/13.
//  Copyright (c) 2013 David Muñoz Fernández. All rights reserved.
//

#import "KitchenSinkViewController.h"
#import "AskerViewController.h"

@interface KitchenSinkViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIView *kitchenSink;
// weak pq todos los NSTimer tienen un puntero strong por el sistema
//  (al igual que los uicontrol por los storyboard)
@property (weak, nonatomic) NSTimer *drainTimer;
// Para evitar en el ipad que se puedan abrir más de un actionsheet
@property (weak, nonatomic) UIActionSheet *sinkControlActionSheet;

@end

@implementation KitchenSinkViewController

#define SINK_CONTROL @"Controles de la cesta"
#define SINK_CONTROL_STOP_DRAIN @"Parar vaciado"
#define SINK_CONTROL_UNSTOP_DRAIN @"Continuar vaciado"
#define SINK_CONTROL_CANCEL @"Cancelar"
#define SINK_CONTROL_EMPTY @"Cesta vacía"

- (IBAction)controlSink:(UIBarButtonItem *)sender {
    if (!self.sinkControlActionSheet) {
        // Según si está el timer funcionando o no, se muestra el mensaje de parar vaciado o arrancarlo
        NSString *drainButton = self.drainTimer ? SINK_CONTROL_STOP_DRAIN : SINK_CONTROL_UNSTOP_DRAIN;
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:SINK_CONTROL
                                                                 delegate:self
                                                        cancelButtonTitle:SINK_CONTROL_CANCEL
                                                   destructiveButtonTitle:SINK_CONTROL_EMPTY
                                                        otherButtonTitles:drainButton, nil];
        [actionSheet showFromBarButtonItem:sender animated:YES];
        self.sinkControlActionSheet = actionSheet; 
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // Elimina todas las subvistas de la cesta (las comidas)
        [self.kitchenSink.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    } else {
        NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([choice isEqualToString:SINK_CONTROL_STOP_DRAIN]){
            [self stopDrainTimer];
        } else if ([choice isEqualToString:SINK_CONTROL_UNSTOP_DRAIN]){
            [self startDrainTimer];
        }
    }
}


#define DISH_CLEAN_INTERVAL 2.0

- (void) cleanDish
{
    // Si está en la pantalla
    if (self.kitchenSink.window) {
        [self addFood:nil];
        [self performSelector:@selector(cleanDish) withObject:nil afterDelay:DISH_CLEAN_INTERVAL];
    }
}


#define DRAIN_DURATION 3.0
#define DRAIN_DELAY 1.0

- (void) startDrainTimer
{
    self.drainTimer = [NSTimer scheduledTimerWithTimeInterval:DRAIN_DURATION/3 target:self selector:@selector(drain:) userInfo:nil repeats:YES];
}

// El método invocado por el selector de NSTimer siempre lleva un argumento (NSTimer)
- (void) drain:(NSTimer *)timer
{
    [self drain];
}

- (void) stopDrainTimer
{
    [self.drainTimer invalidate];
    self.drainTimer = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startDrainTimer];
    [self cleanDish];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopDrainTimer];
}

- (void) drain
{
    for (UIView *view in self.kitchenSink.subviews) {
        CGAffineTransform transform = view.transform;
        if (CGAffineTransformIsIdentity(transform)){
            // Queremos que gire 360º, por eso hacemos la transformación en 3 fases
            //  Con 1 fase el inicio y el fin sería el mismo lugar, por tanto no habría animación
            //  Con 2 fases una vez que estamos a mitad de la rotación, se podría ir al inicio por el mismo lado que vino
            //  Con 3 fases nos aseguramos que hace el giro completo y siempre en el mismo sentido
            [UIView animateWithDuration:DRAIN_DURATION delay:DRAIN_DELAY options:UIViewAnimationOptionCurveEaseIn animations:^{
                // 2*PI -> toda la cirfunferencia
                view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.7, 0.7), 2*M_PI/3);
            } completion:^(BOOL finished) {
                if (finished) {
                    // Animamos el siguiente tercio (2/3)
                    [UIView animateWithDuration:DRAIN_DURATION delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.4, 0.4), -2*M_PI/3);
                    } completion:^(BOOL finished) {
                        if (finished) {
                            // Animamos el último tercio (3/3)
                            [UIView animateWithDuration:DRAIN_DURATION delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                view.transform = CGAffineTransformScale(transform, 0.1, 0.1);
                            } completion:^(BOOL finished) {
                                if (finished) {
                                    // Elimina la vista
                                    [view removeFromSuperview];
                                }
                            }];
                        }
                    }];
                }
            }];
        }
    }
}


#define MOVE_DURATION 3.0

- (IBAction)tap:(UITapGestureRecognizer *)sender
{
    CGPoint tapLocation = [sender locationInView:self.kitchenSink];
    for (UIView *view in self.kitchenSink.subviews) {
        if (CGRectContainsPoint(view.frame, tapLocation)) {
            [UIView animateWithDuration:MOVE_DURATION delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setRandomLocationForView:view];
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.99, 0.99);
            } completion: ^(BOOL finished){
                view.transform = CGAffineTransformIdentity;
                
            }];
        }
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Ask"]) {
        AskerViewController *asker = segue.destinationViewController;
        asker.question = @"¿Qué comida quieres en la cesta?";
    }
}

- (IBAction) cancelAsking:(UIStoryboardSegue *)segue
{
}

- (IBAction) doneAsking:(UIStoryboardSegue *)segue
{
    AskerViewController *asker = segue.sourceViewController;
    [self addFood:asker.answer];
    NSLog(@"%@", asker.answer);
}


#define BLUE_FOOD @"Gelatina"
#define GREEN_FOOD @"Lechuga"
#define ORANGE_FOOD @"Naranja"
#define RED_FOOD @"Tomate"
#define PURPLE_FOOD @"Berenjena"
#define BROWN_FOOD @"Patata"

- (void) addFood:(NSString *)food
{
    UILabel *foodLabel = [[UILabel alloc] init];
    
    // Diccionario estático con un listado de comidas y colores
    static NSDictionary *foods = nil;
    if (!foods) {
        foods = @{ BLUE_FOOD: [UIColor blueColor],
                   GREEN_FOOD: [UIColor greenColor],
                   ORANGE_FOOD: [UIColor orangeColor],
                   RED_FOOD: [UIColor redColor],
                   PURPLE_FOOD: [UIColor purpleColor],
                   BROWN_FOOD: [UIColor brownColor] };
    }
    
    if (![food length]){
        // No se ha elegido comida, selecciona una aleatoria y le asocia el color
        food = [[foods allKeys] objectAtIndex:arc4random()%[foods count]];
        foodLabel.textColor = [foods objectForKey:food];
    }
    
    foodLabel.text = food;
    foodLabel.font = [UIFont systemFontOfSize:46];
    foodLabel.backgroundColor = [UIColor clearColor];
    [self setRandomLocationForView:foodLabel];
    [self.kitchenSink addSubview:foodLabel];
}

- (void) setRandomLocationForView:(UIView *)view
{
    // Tamaño intrínseco de la vista al contenido del botón
    [view sizeToFit];
    
    // Establece el tamaño y la posición del botón (aleatoria)
    CGRect sinkBounds = CGRectInset(self.kitchenSink.bounds, view.frame.size.width/2, view.frame.size.height/2);
    CGFloat x = arc4random() % (int) sinkBounds.size.width + view.frame.size.width/2;
    CGFloat y = arc4random() % (int) sinkBounds.size.height + view.frame.size.height/2;
    view.center = CGPointMake(x, y);
}

@end
