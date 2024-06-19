
-- ------------------------------------- Nashville Housing Data cleaning ------------------------------------------------------

USE nashville_housing_data;
create table if not exists nashville_housing(
UniqueID int(10) not null primary key,
ParcelID varchar(18) not null,
LandUse	varchar(50) not null,
PropertyAddress	varchar(200) not null,
SaleDate date not null,
SalePrice double(10,0)	not null,
LegalReference varchar(20) not null,
SoldAsVacant char(5) not null,
OwnerName varchar(200) null,
OwnerAddress varchar(200) null,
Acreage	float(3,2) null,
TaxDistrict	varchar(50) null,
LandValue decimal(10,0) null,
BuildingValue decimal(10,0) null,
TotalValue	decimal(10,0) null,
YearBuilt year null,
Bedrooms int null,
FullBath int null,
HalfBath int null
);

select * from nashville_housing;

-- Finding property address values that are null but have same parcelID
select a.ParcelID, a.PropertyAddress,b.ParcelID,b.PropertyAddress,ifNull(a.PropertyAddress,b.PropertyAddress)
from nashville_housing a 
join nashville_housing b on
a.ParcelID = b.ParcelID and
a.UniqueID <> b.UniqueID
where a.PropertyAddress is Null;

-- populating propertyAddress values which are null but share same parcel ID's with the data rows that have propertyaddress.
update nashville_housing a 
 join nashville_housing b on
a.ParcelID = b.ParcelID and
a.UniqueID <> b.UniqueID
set a.PropertyAddress = ifNull(a.PropertyAddress , b.PropertyAddress)
where a.PropertyAddress is Null;

-- separting the property address in diff columns of address , city
select 
substring(PropertyAddress,1,locate(',', PropertyAddress) - 1) as address ,
substring(PropertyAddress,locate(',', PropertyAddress) + 1,length(PropertyAddress)) as city from nashville_housing;

Alter table nashville_housing
add PropertySplitAddress varchar(255);

update nashville_housing
set PropertySplitAddress = substring(PropertyAddress,1,locate(',', PropertyAddress) - 1);

Alter table nashville_housing
add PropertySplitCity varchar(255);

update nashville_housing
set PropertySplitCity =  substring(PropertyAddress,locate(',', PropertyAddress) + 1,length(PropertyAddress));

-- separting the Owner address in diff columns of Address , City, State

select OwnerAddress from nashville_housing;
select substring(OwnerAddress,1,locate(',',OwnerAddress)- 1) as address,
       substring(OwnerAddress,locate(',',OwnerAddress) + 1,length(OwnerAddress)) as city,
       right(OwnerAddress,3) as state
       From nashville_housing;
       
Alter table nashville_housing
add OwnerSplitAddress varchar(255);

Alter table nashville_housing
add OwnerSplitCity varchar(35);

Alter table nashville_housing
add OwnerSplitState varchar(35);

Update nashville_housing
set OwnerSplitAddress = substring(OwnerAddress,1,locate(',',OwnerAddress)- 1);
  
Update nashville_housing
set OwnerSplitCity = substring(OwnerAddress,locate(',',OwnerAddress) + 1,length(OwnerAddress));

Update nashville_housing
set OwnerSplitState =  right(OwnerAddress,3);

-- Change Y and N to Yes and No in "SoldAsVacant" field
select Distinct(SoldAsVacant), Count(SoldAsVacant)
from nashville_housing
group by SoldAsVacant
Order by 2; 

select SoldAsVacant,
     case when SoldAsVacant = 'Y' 
          then 'Yes'
          when SoldAsVacant = 'N'
          then 'No'
          else SoldAsVacant
          end as sold_preference
from nashville_housing;

update nashville_housing
set SoldAsVacant = case when SoldAsVacant = 'Y' 
          then 'Yes'
          when SoldAsVacant = 'N'
          then 'No'
          else SoldAsVacant
          end;
          
 -- Remove duplicates using common table expression
 
with row_num_cte as (
  select * , row_number() 
				 over(partition by ParcelID,
								 PropertyAddress,
								 SaleDate,
								  SalePrice,
								 LegalReference
					order by UniqueID
					) as row_num
  from nashville_housing
		)
 select * from row_num_cte
  where row_num > 1
order by PropertyAddress;

-- We can't delete rows from cte by doing below process , Hence will get Error Code: 1288. 
-- The target table row_num_cte of the DELETE is not updatable

-- delete from row_num_cte where row_num > 1;  


-- Correct way,but this will delete the raw data from actual table i.e. nashville_housing.Deleting raw data is a bad practice.
delete nh
from nashville_housing nh INNER JOIN row_num_cte r ON nh.UniqueID = r.UniqueID
where row_num>1;




 