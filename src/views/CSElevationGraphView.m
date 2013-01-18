//
//  CSElevationGraphView.m
//  CycleStreets
//
//  Created by Neil Edwards on 07/12/2012.
//  Copyright (c) 2012 CycleStreets Ltd. All rights reserved.
//

#import "CSElevationGraphView.h"
#import "CSPointVO.h"
#import "UIView+Additions.h"
#import <QuartzCore/QuartzCore.h>
#import "GlobalUtilities.h"
#import "ViewUtilities.h"
#import "ExpandedUILabel.h"
#import "SegmentVO.h"
#import "BUCalloutView.h"


#define graphHeight 80
@interface CSElevationGraphView()

@property(nonatomic,strong)  CSGraphView				*graphView;
@property(nonatomic,strong)  CAShapeLayer				*graphMaskLayer;
@property(nonatomic,strong)  UIBezierPath				*graphPath;

@property(nonatomic,strong)  ExpandedUILabel			*yAxisLabel;
@property(nonatomic,strong)  ExpandedUILabel			*xAxisLabel;


@property(nonatomic,strong)  BUCalloutView				*calloutView;

@property(nonatomic,strong)  NSMutableArray				*elevationArray;


@end

@implementation CSElevationGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialise];
    }
    return self;
}

-(void)initialise{
	
	self.yAxisLabel=[[ExpandedUILabel alloc]initWithFrame:CGRectMake(0, 0, 25, 15)];
	_yAxisLabel.textColor=[UIColor whiteColor];
	_yAxisLabel.font=[UIFont systemFontOfSize:13];
	_yAxisLabel.textAlignment=UITextAlignmentCenter;
	_yAxisLabel.layer.cornerRadius=4;
	_yAxisLabel.multiline=NO;
	_yAxisLabel.insetValue=3;
	_yAxisLabel.backgroundColor=UIColorFromRGB(0xF76117);
	_yAxisLabel.text=@"m";
	[self addSubview:_yAxisLabel];
	
	self.xAxisLabel=[[ExpandedUILabel alloc]initWithFrame:CGRectMake(20, self.height, 25, 15)];
	_xAxisLabel.textColor=[UIColor whiteColor];
	_xAxisLabel.multiline=NO;
	_xAxisLabel.insetValue=3;
	_xAxisLabel.font=[UIFont systemFontOfSize:13];
	_xAxisLabel.textAlignment=UITextAlignmentCenter;
	_xAxisLabel.layer.cornerRadius=4;
	_xAxisLabel.backgroundColor=UIColorFromRGB(0xF76117);
	_xAxisLabel.text=@"km";
	[self addSubview:_xAxisLabel];
	
	[ViewUtilities alignView:_xAxisLabel withView:self :BURightAlignMode :BUBottomAlignMode];
	
	
	self.graphView=[[CSGraphView alloc] initWithFrame:CGRectMake(0, 20, UIWIDTH, graphHeight)];
	_graphView.delegate=self;
	_graphView.backgroundColor=UIColorFromRGB(0x509720);
	
	self.graphMaskLayer = [CAShapeLayer layer];
	[_graphMaskLayer setFrame:CGRectMake(0, 0, UIWIDTH, graphHeight)];
	_graphView.layer.mask = _graphMaskLayer;
	
	[self addSubview:_graphView];
	
	
	self.calloutView=[[BUCalloutView alloc]initWithFrame:CGRectMake(20, 0, 80, 30)];
	_calloutView.fillColor=UIColorFromRGB(0x006EA6);
	_calloutView.cornerRadius=6;
	[_calloutView updateTitleLabel:@"25 miles"];
	[self addSubview:_calloutView];
	
	


}


-(void)handleTouchInGraph:(CGPoint)point{
	
	if ([_graphPath containsPoint:point]) {
		
		if(_calloutView.isHidden==YES){
			
			_calloutView.visible=YES;
			_calloutView.alpha=0;
			
			[self.delegate touchInGraph:YES];
			
			[UIView animateWithDuration:0.3 animations:^{
				_calloutView.alpha=1;
			} completion:^(BOOL finished) {
				
			}];
		}
		
		float xpos=point.x;
		
		
		float xpercent=MAX(MIN((float)xpos/(float)_graphView.width,1),0);
		int segmentindex=floor(xpercent*(_elevationArray.count-1));
		
		//BetterLog(@"xpercent=%f",xpercent);
		//BetterLog(@"segmentindex=%i",segmentindex);
		
		[_calloutView updateTitleLabel:[NSString stringWithFormat:@"%@m %@",_elevationArray[segmentindex],[_dataProvider lengthPercentStringForPercent:xpercent]]];
		
		// TODO: callout bg should adjust arrow position, end, center, end
		
		float calloutxpos=(_graphView.x+xpos)-(_calloutView.width/2);
		calloutxpos=MAX(0, MIN((280-_calloutView.width), calloutxpos));
		_calloutView.x=calloutxpos;
		
		
	}

	
}

-(void)cancelTouchInGraph{
	
	if(_calloutView.isHidden==NO){
		
		[UIView animateWithDuration:0.3 animations:^{
			_calloutView.alpha=0;
		} completion:^(BOOL finished) {
			_calloutView.visible=NO;
			
		}];
		
		
	}
	
	[self.delegate touchInGraph:NO];
	
}



-(void)update{
	
	if(_elevationArray==nil)
		self.elevationArray=[NSMutableArray array];
	[_elevationArray removeAllObjects];
	
	
	[_graphView removeAllSubViews];
	
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path moveToPoint:CGPointMake(0, _graphView.height)];
	
	// temp
	int maxelevation=[_dataProvider maxElevation]; // max elevation for all segemnts
	int index=0;
	int xpos=0;
	float currentDistance=0;
	
	
	_yAxisLabel.text=[NSString stringWithFormat:@"%i m",maxelevation];
	_xAxisLabel.text=_dataProvider.lengthString;
	[ViewUtilities alignView:_xAxisLabel withView:self :BURightAlignMode :BUBottomAlignMode];
	
	// startpoint
	SegmentVO *segment=_dataProvider.segments[0];
	float startpercent=(float)segment.segmentElevation/(float)maxelevation;
	startpercent=1-startpercent;
	int startypos=graphHeight*startpercent;
	[path addLineToPoint:CGPointMake(0, startypos)];
	//
	
	
	// ideal form is method to reduce >280 data sets to 280 across all segments
	// less than 280 can be used as is with per segment distance increment
	
	for (SegmentVO *segment in _dataProvider.segments) {
		
		// y value
		int value=segment.segmentElevation;
		float ypercent=(float)value/(float)maxelevation;
		ypercent=1-ypercent;
		int ypos=graphHeight*ypercent;
		
		[_elevationArray addObject:BOX_INT(value)];
		
		// x value
		currentDistance+=[segment segmentDistance];
		float xpercent=currentDistance/[_dataProvider.length floatValue];
		xpos=UIWIDTH*xpercent;
		
		// ensures last point is max x, handles rounding errors
		if (index==_dataProvider.segments.count-1) {
			xpos=UIWIDTH;
		}
		
		BetterLog(@"point %i, ypos: %i  xpos:%i (xp: %i= %f)",index,ypos,xpos,[segment segmentDistance],xpercent);
		
		// debug only
		/*
		ExpandedUILabel *label=[[ExpandedUILabel alloc] initWithFrame:CGRectMake(xpos-1, ypos-1, 14,14)];
		label.backgroundColor=[UIColor clearColor];
		label.font=[UIFont systemFontOfSize:11];
		label.text=[NSString stringWithFormat:@"%i",index];
		[_graphView addSubview:label];
		 */
		//

		[path addLineToPoint:CGPointMake(xpos, ypos)];
			
		index++;
				
	}
	
	[path addLineToPoint:CGPointMake(UIWIDTH, _graphView.height)];

	 
	self.graphPath=path;
	[_graphMaskLayer setPath:path.CGPath];
	
}




@end
