//
//  AccountsController.m
//  Saccharin
//
//  Created by Adrian on 1/19/10.
//  Copyright 2010 akosma software. All rights reserved.
//

#import "ListController.h"
#import "FatFreeCRMProxy.h"
#import "Account.h"
#import "NSDate+Saccharin.h"

@implementation ListController

@synthesize listedClass = _listedClass;
@synthesize delegate = _delegate;

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) 
    {
        _navigationController = [[UINavigationController alloc] initWithRootViewController:self];
        
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
        _searchBar.placeholder = @"Search";
        _searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar 
                                                              contentsController:self];
        _searchController.delegate = self;
        _searchController.searchResultsDataSource = self;
        _searchController.searchResultsDelegate = self;
        
        _data = [[NSMutableArray alloc] initWithCapacity:20];
        _searchData = [[NSMutableArray alloc] initWithCapacity:20];
        
        _pageCounter = 1;
        _moreToLoad = YES;
        _firstLoad = YES;
    }
    return self;
}

- (void)dealloc 
{
    [_navigationController release];
    [_searchBar release];
    [_searchController release];
    [_data release];
    [_searchData release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.tableView.tableHeaderView = _searchBar;
    self.tableView.rowHeight = 60.0;
    self.searchDisplayController.searchResultsTableView.rowHeight = 60.0;
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    if (_firstLoad)
    {
        _firstLoad = NO;
        [[FatFreeCRMProxy sharedFatFreeCRMProxy] loadList:_listedClass page:_pageCounter];
    }
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark NSNotification methods

- (void)didReceiveData:(NSNotification *)notification
{
    NSArray *newData = [[notification userInfo] objectForKey:@"data"];
    _moreToLoad = [newData count] > 0;
    if (self.searchDisplayController.active)
    {
        [_searchData addObjectsFromArray:newData];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    else 
    {
        [_data addObjectsFromArray:newData];
        [self.tableView reloadData];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // When the user scrolls to the bottom, we load a new page of information automatically.
    if (!self.searchDisplayController.active && _moreToLoad && 
        scrollView.contentOffset.y + 372.0 >= scrollView.contentSize.height)
    {
        ++_pageCounter;
        [[FatFreeCRMProxy sharedFatFreeCRMProxy] loadList:_listedClass page:_pageCounter];
    }
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (self.searchDisplayController.active)
	{
        return [_searchData count];
    }
    if (_moreToLoad)
    {
        return [_data count] + 1;
    }
    return [_data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                       reuseIdentifier:CellIdentifier] autorelease];
    }

    NSArray *array = (self.searchDisplayController.active) ? _searchData : _data;
    
    if (indexPath.row < [array count])
    {
        BaseEntity *item = [array objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.textLabel.text = item.name;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = [item description];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = @"Loading...";
        cell.textLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegate respondsToSelector:@selector(listController:didTapAccessoryForEntity:)])
    {
        NSArray *array = (self.searchDisplayController.active) ? _searchData : _data;
        BaseEntity *entity = [array objectAtIndex:indexPath.row];
        [_delegate listController:self didTapAccessoryForEntity:entity];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if ([_delegate respondsToSelector:@selector(listController:didSelectEntity:)])
    {
        NSArray *array = (self.searchDisplayController.active) ? _searchData : _data;
        BaseEntity *entity = [array objectAtIndex:indexPath.row];
        [_delegate listController:self didSelectEntity:entity];
    }
}

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
	[_searchData removeAllObjects];
	
    if (searchText != nil && [searchText length] > 0)
    {
        [[FatFreeCRMProxy sharedFatFreeCRMProxy] cancelConnections];
        [[FatFreeCRMProxy sharedFatFreeCRMProxy] searchList:_listedClass query:searchText];
    }
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSInteger index = [_searchController.searchBar selectedScopeButtonIndex];
    NSArray *buttons = [_searchController.searchBar scopeButtonTitles];
    NSString *scope = [buttons objectAtIndex:index];
    [self filterContentForSearchText:searchString scope:scope];
    
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSArray *buttons = [_searchController.searchBar scopeButtonTitles];
    NSString *scope = [buttons objectAtIndex:searchOption];
    [self filterContentForSearchText:_searchController.searchBar.text scope:scope];
    
    return NO;
}

@end
